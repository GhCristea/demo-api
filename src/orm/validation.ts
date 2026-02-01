import type { BaseEntity, EntityClass, Target } from "./types.ts";

interface ValidationRule {
  propertyKey: string;
  type: "REQUIRED" | "MIN_LENGTH" | "MAX_LENGTH" | "CUSTOM";
  value?: number;
  message?: string;
}

const validationMetadata = new WeakMap<EntityClass, ValidationRule[]>();

function addRule(target: Target, rule: ValidationRule) {
  const constructor = target.constructor as EntityClass;
  const rules = validationMetadata.get(constructor) ?? [];
  rules.push(rule);
  validationMetadata.set(constructor, rules);
}

export function IsNotEmpty(message?: string) {
  return function (target: Target, propertyKey: string) {
    addRule(target, {
      propertyKey,
      type: "REQUIRED",
      message: message ?? `${propertyKey} is required`
    });
  };
}

export function MinLength(min: number, message?: string) {
  return function (target: Target, propertyKey: string) {
    addRule(target, {
      propertyKey,
      type: "MIN_LENGTH",
      value: min,
      message:
        message ?? `${propertyKey} must be at least ${String(min)} characters`
    });
  };
}

export function validate<T extends BaseEntity>(
  entityClass: EntityClass<T>,
  data: Record<string, unknown>,
  isPartial = false
): string[] {
  const rules = validationMetadata.get(entityClass);
  if (!rules) return [];

  const errors: string[] = [];

  for (const rule of rules) {
    const value = data[rule.propertyKey];

    if (isPartial && value === undefined) {
      continue;
    }
    if (rule.type === "REQUIRED") {
      if (!value) {
        errors.push(rule.message ?? `${rule.propertyKey} is required`);
      }
    }

    if (!value) continue;

    if (rule.type === "MIN_LENGTH" && rule.value) {
      if (typeof value === "string" && value.length < rule.value) {
        errors.push(
          rule.message ??
            `${rule.propertyKey} must be at least ${String(rule.value)} characters`
        );
      }
    }
  }

  return errors;
}
