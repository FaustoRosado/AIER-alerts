/**
 * AIER Alert System - TypeScript Type Definitions
 * 
 * TypeScript vs JavaScript:
 * - TypeScript adds static typing to catch errors at compile time
 * - JavaScript is dynamically typed, errors only appear at runtime
 * - TypeScript provides better IDE autocomplete and documentation
 * - TypeScript code is transpiled to JavaScript for browser execution
 */

/**
 * Patient data structure
 * 
 * In JavaScript, you would just use an object without type definitions:
 * const patient = { patient_id: "PT-001", age: 45, ... }
 * 
 * In TypeScript, we define the exact structure with types:
 */
export interface Patient {
  patient_id: string;              // string type - must be text
  timestamp: number;               // number type - Unix timestamp
  Pregnancies: number;
  Glucose: number;
  BloodPressure: number;
  SkinThickness: number;
  Insulin: number;
  BMI: number;
  DiabetesPedigreeFunction: number;
  Age: number;
  Outcome: 0 | 1;                  // Union type - can only be 0 or 1
  risk_score: number;
  risk_level: RiskLevel;           // Custom type (defined below)
  age_group: string;
  bmi_category: string;
}

/**
 * Risk level type
 * 
 * Union type - variable can only be one of these exact strings
 * JavaScript equivalent would allow any string, potentially causing bugs
 */
export type RiskLevel = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

/**
 * Scatter plot data point
 * Used for D3.js visualization
 */
export interface ScatterDataPoint {
  patient_id: string;
  bmi: number;
  glucose: number;
  age: number;
  risk_level: RiskLevel;
  outcome: 0 | 1;
}

/**
 * Statistics data structure
 */
export interface Statistics {
  total_patients: number;
  diabetes_prevalence: number;
  risk_distribution: Record<RiskLevel, number>;  // Object with RiskLevel keys
  age_distribution: Record<string, number>;
  averages: {
    glucose: number;
    bmi: number;
    age: number;
  };
}

/**
 * API Response wrapper
 * 
 * Generic type T - allows reuse for different data types
 * In JavaScript, you'd just access response.data without type safety
 */
export interface ApiResponse<T> {
  status: 'success' | 'error';
  data: T;                         // Generic type - replaced with actual type when used
  metadata: {
    timestamp: string;
    [key: string]: any;            // Index signature - allows additional properties
  };
}

/**
 * API Error response
 */
export interface ApiError {
  status: 'error';
  error: {
    code: string;
    message: string;
    details?: string;              // Optional property - may or may not exist
  };
}

/**
 * Chart configuration
 */
export interface ChartConfig {
  width: number;
  height: number;
  margin: {
    top: number;
    right: number;
    bottom: number;
    left: number;
  };
  colors: Record<RiskLevel, string>;
}

/**
 * Distribution data for charts
 */
export interface DistributionData {
  age_distribution: Record<string, number>;
  risk_distribution: Record<RiskLevel, number>;
}
