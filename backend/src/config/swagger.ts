import swaggerJsdoc from 'swagger-jsdoc';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Get port from environment or use default 4000 (matching server.ts)
const PORT = process.env.PORT || '4000';
const serverUrl = `http://localhost:${PORT}`;

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'NewsEva API',
      version: '1.0.0',
      description: 'API documentation for NewsEva backend service',
      contact: {
        name: 'API Support',
      },
    },
    servers: [
      {
        url: serverUrl,
        description: 'Development server',
      },
    ],
    components: {
      schemas: {
        NewsItem: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'Unique identifier for the news item',
            },
            title: {
              type: 'string',
              description: 'Title of the news article',
            },
            summary: {
              type: 'string',
              description: 'Summary or description of the article',
            },
            url: {
              type: 'string',
              format: 'uri',
              description: 'URL to the full article',
            },
            imageUrl: {
              type: 'string',
              format: 'uri',
              description: 'URL to the article image',
            },
            publishedAt: {
              type: 'string',
              format: 'date-time',
              description: 'Publication date and time',
            },
            source: {
              type: 'string',
              description: 'News source name',
            },
            language: {
              type: 'string',
              description: 'Language code (ISO 639-1)',
            },
          },
          required: ['id', 'title', 'url', 'source'],
        },
        NewsResponse: {
          type: 'object',
          properties: {
            data: {
              type: 'array',
              items: {
                $ref: '#/components/schemas/NewsItem',
              },
            },
          },
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            ok: {
              type: 'boolean',
              example: false,
            },
            error: {
              type: 'string',
              description: 'Error message',
            },
          },
        },
        SuccessResponse: {
          type: 'object',
          properties: {
            ok: {
              type: 'boolean',
              example: true,
            },
          },
        },
        SendOtpRequest: {
          type: 'object',
          required: ['phone'],
          properties: {
            phone: {
              type: 'string',
              description: 'Phone number in E.164 format (e.g., +919876543210)',
              example: '+919876543210',
            },
          },
        },
        VerifyOtpRequest: {
          type: 'object',
          required: ['phone', 'code'],
          properties: {
            phone: {
              type: 'string',
              description: 'Phone number in E.164 format (e.g., +919876543210)',
              example: '+919876543210',
            },
            code: {
              type: 'string',
              description: 'OTP code received via SMS',
              example: '123456',
            },
          },
        },
        HealthCheckResponse: {
          type: 'object',
          properties: {
            ok: {
              type: 'boolean',
              example: true,
            },
          },
        },
      },
    },
  },
  apis: ['./src/**/*.ts'], // Path to the API files
};

export const swaggerSpec = swaggerJsdoc(options);

