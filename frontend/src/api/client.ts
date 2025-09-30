/**
 * AIER Alert System - API Client
 * 
 * TypeScript vs JavaScript differences demonstrated:
 * - Type annotations for parameters and return values
 * - Interface definitions for response data
 * - Compile-time type checking
 * - Better error handling with typed exceptions
 */

import axios, { AxiosInstance, AxiosError } from 'axios';
import type { 
  ApiResponse, 
  ApiError, 
  Patient, 
  Statistics, 
  ScatterDataPoint,
  DistributionData 
} from '../types/patient';

/**
 * API Base URL
 * In production, this would come from environment variables
 */
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

/**
 * API Client Class
 * 
 * TypeScript differences:
 * - Private properties with 'private' keyword (JS uses # prefix or convention)
 * - Type annotations on all methods
 * - Generic types for flexible API responses
 */
class ApiClient {
  private client: AxiosInstance;  // Type annotation - must be AxiosInstance

  /**
   * Constructor with typed parameters
   * JavaScript: constructor(baseURL = 'http://localhost:8000')
   * TypeScript: Adds type annotation for parameter
   */
  constructor(baseURL: string = API_BASE_URL) {
    this.client = axios.create({
      baseURL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor for logging
    this.client.interceptors.request.use(
      (config) => {
        console.log(`API Request: ${config.method?.toUpperCase()} ${config.url}`);
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError<ApiError>) => {  // TypeScript: Typed error parameter
        return this.handleError(error);
      }
    );
  }

  /**
   * Handle API errors with typed error responses
   * 
   * TypeScript: Return type annotation ensures consistent error handling
   * JavaScript: No guarantee about what's returned
   */
  private handleError(error: AxiosError<ApiError>): never {
    if (error.response) {
      // Server responded with error
      const apiError = error.response.data;
      console.error('API Error:', apiError);
      throw new Error(apiError.error?.message || 'API request failed');
    } else if (error.request) {
      // Request made but no response
      console.error('Network Error:', error.message);
      throw new Error('Network error - please check your connection');
    } else {
      // Error in request configuration
      console.error('Request Error:', error.message);
      throw new Error('Failed to make request');
    }
  }

  /**
   * Get list of patients
   * 
   * TypeScript differences:
   * - Optional parameters with '?' (limit?: number)
   * - Return type Promise<Patient[]> guarantees array of Patient objects
   * - JavaScript: No type safety, could return anything
   * 
   * @param limit - Maximum number of patients to return
   * @param riskLevel - Filter by risk level
   * @returns Promise resolving to array of Patient objects
   */
  async getPatients(
    limit?: number,
    riskLevel?: string
  ): Promise<Patient[]> {  // Return type annotation
    const params: Record<string, string | number> = {};  // Typed params object
    
    if (limit) params.limit = limit;
    if (riskLevel) params.risk_level = riskLevel;

    const response = await this.client.get<ApiResponse<{ patients: Patient[] }>>(
      '/api/patients',
      { params }
    );

    return response.data.data.patients;
  }

  /**
   * Get single patient by ID
   * 
   * @param patientId - Patient identifier
   * @returns Promise resolving to Patient object
   */
  async getPatient(patientId: string): Promise<Patient> {
    const response = await this.client.get<ApiResponse<Patient>>(
      `/api/patients/${patientId}`
    );

    return response.data.data;
  }

  /**
   * Get overall statistics
   * 
   * @returns Promise resolving to Statistics object
   */
  async getStatistics(): Promise<Statistics> {
    const response = await this.client.get<ApiResponse<Statistics>>(
      '/api/statistics'
    );

    return response.data.data;
  }

  /**
   * Get scatter plot data
   * 
   * @returns Promise resolving to array of scatter data points
   */
  async getScatterData(): Promise<ScatterDataPoint[]> {
    const response = await this.client.get<ApiResponse<ScatterDataPoint[]>>(
      '/api/visualizations/scatter'
    );

    return response.data.data;
  }

  /**
   * Get distribution data for charts
   * 
   * @returns Promise resolving to DistributionData object
   */
  async getDistributionData(): Promise<DistributionData> {
    const response = await this.client.get<ApiResponse<DistributionData>>(
      '/api/visualizations/distribution'
    );

    return response.data.data;
  }

  /**
   * Health check
   * 
   * @returns Promise resolving to health status
   */
  async healthCheck(): Promise<{ status: string }> {
    const response = await this.client.get<{ status: string }>('/health');
    return response.data;
  }
}

/**
 * Export singleton instance
 * 
 * TypeScript: Type is inferred as ApiClient
 * JavaScript: No type information
 */
export const apiClient = new ApiClient();

/**
 * Export class for testing or custom instances
 */
export default ApiClient;
