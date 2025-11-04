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
        User: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            phone: { type: 'string' },
            email: { type: 'string', format: 'email' },
            displayName: { type: 'string' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
          required: ['_id', 'createdAt', 'updatedAt']
        },
        Conversation: {
          type: 'object',
          properties: {
            _id: { type: 'string', description: 'Conversation ID' },
            type: { type: 'string', enum: ['solo', 'group'] },
            memberIds: { type: 'array', items: { type: 'string', description: 'Profile _id (E.164 phone)', example: '+919876543210' } },
            adminIds: { type: 'array', items: { type: 'string' } },
            name: { type: 'string' },
            avatarUrl: { type: 'string', format: 'uri' },
            lastMessageId: { type: 'string' },
            lastMessageAt: { type: 'string', format: 'date-time' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
          required: ['_id', 'type', 'memberIds', 'createdAt', 'updatedAt']
        },
        MessageReceipt: {
          type: 'object',
          properties: {
            userId: { type: 'string' },
            deliveredAt: { type: 'string', format: 'date-time' },
            seenAt: { type: 'string', format: 'date-time' },
          },
          required: ['userId']
        },
        Message: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            conversationId: { type: 'string' },
            senderId: { type: 'string', description: 'Profile _id (E.164 phone)', example: '+919876543210' },
            type: { type: 'string', enum: ['text', 'image', 'voice'] },
            text: { type: 'string' },
            mediaUrl: { type: 'string', format: 'uri' },
            mediaMimeType: { type: 'string' },
            voiceDurationMs: { type: 'integer' },
            receipts: { type: 'array', items: { $ref: '#/components/schemas/MessageReceipt' } },
            editedAt: { type: 'string', format: 'date-time' },
            deletedAt: { type: 'string', format: 'date-time' },
            deletedForUserIds: { type: 'array', items: { type: 'string' } },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
          required: ['_id', 'conversationId', 'senderId', 'type', 'createdAt', 'updatedAt']
        },
        Profile: {
          type: 'object',
          properties: {
            _id: { type: 'string', description: 'User ID (phone in E.164)' },
            displayName: { type: 'string' },
            imageUrl: { type: 'string', format: 'uri', description: 'HTTPS image URL' },
            language: { type: 'string', description: 'ISO 639-1 code' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
          required: ['_id', 'createdAt', 'updatedAt']
        },
        MediaUploadResponse: {
          type: 'object',
          properties: {
            fileId: { type: 'string' },
            contentType: { type: 'string' },
            sizeBytes: { type: 'integer' },
            thoughtId: { type: 'string', nullable: true, description: 'Thought id if provided during upload' },
          },
        },
        Thought: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'Thought ID' },
            newsUrl: { type: 'string', format: 'uri', description: 'Canonical news article URL' },
            userId: { type: 'string', description: 'Author Profile _id (E.164 phone)', example: '+919876543210' },
            contentType: { type: 'string', enum: ['text', 'audio', 'video'] },
            content: {
              oneOf: [
                {
                  type: 'object',
                  properties: { type: { const: 'text' }, text: { type: 'string' } },
                  required: ['type', 'text'],
                },
                {
                  type: 'object',
                  properties: {
                    type: { const: 'audio' },
                    audioUrl: { type: 'string', format: 'uri' },
                    transcript: { type: 'string' },
                    audioFileId: { type: 'string' },
                    mediaUrl: { type: 'string', format: 'uri' },
                  },
                  required: ['type'],
                },
                {
                  type: 'object',
                  properties: {
                    type: { const: 'video' },
                    videoUrl: { type: 'string', format: 'uri' },
                    thumbnailUrl: { type: 'string', format: 'uri' },
                    caption: { type: 'string' },
                    videoFileId: { type: 'string' },
                    mediaUrl: { type: 'string', format: 'uri' },
                  },
                  required: ['type'],
                },
              ],
            },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
          required: ['id', 'newsUrl', 'userId', 'contentType', 'content', 'createdAt', 'updatedAt'],
          example: {
            id: 't_01HF3...',
            newsUrl: 'https://www.bbc.com/hindi/articles/cp857188z40o',
            userId: 'user123',
            contentType: 'audio',
            content: {
              type: 'audio',
              audioFileId: '66ff1c1e2f1a4d1f9e6b1234',
              mediaUrl: '/api/v1/media/66ff1c1e2f1a4d1f9e6b1234/stream'
            },
            createdAt: '2025-11-04T06:12:00.000Z',
            updatedAt: '2025-11-04T06:12:00.000Z',
          },
        },
        CreateThoughtRequest: {
          type: 'object',
          required: ['newsUrl', 'userId', 'contentType', 'content'],
          properties: {
            newsUrl: { type: 'string', format: 'uri', description: 'News article URL from /news' },
            userId: { type: 'string', description: 'Author Profile _id (E.164 phone)', example: '+919876543210' },
            contentType: { type: 'string', enum: ['text', 'audio', 'video'] },
            content: { $ref: '#/components/schemas/Thought/properties/content' },
          },
          example: {
            newsUrl: 'https://www.bbc.com/hindi/articles/cp857188z40o?at_medium=RSS&at_campaign=rss',
            userId: 'user123',
            contentType: 'text',
            content: { type: 'text', text: 'My thought about this article' },
          },
        },
        ThoughtsListResponse: {
          type: 'object',
          properties: {
            data: {
              type: 'array',
              items: { $ref: '#/components/schemas/Thought' },
            },
          },
        },
        ThoughtResponse: {
          type: 'object',
          properties: { data: { $ref: '#/components/schemas/Thought' } },
        },
        
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
            displayName: {
              type: 'string',
              description: 'User\'s display name (used when creating first-time user)',
              example: 'Grandpa Ram',
            },
          },
        },
        LoginResponse: {
          type: 'object',
          properties: {
            ok: { type: 'boolean', example: true },
            user: { $ref: '#/components/schemas/User' },
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

