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
        CommunityAuthor: {
          type: 'object',
          properties: {
            userId: { type: 'string' },
            displayName: { type: 'string' },
            imageUrl: { type: 'string', format: 'uri' },
          },
          required: ['userId']
        },
        CommunityPost: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            author: { $ref: '#/components/schemas/CommunityAuthor' },
            text: { type: 'string' },
            media: { type: 'array', items: { type: 'object', properties: { type: { type: 'string', enum: ['image','video','audio'] }, url: { type: 'string', format: 'uri' }, mimeType: { type: 'string' } }, required: ['type','url'] } },
            likeUserIds: { type: 'array', items: { type: 'string' } },
            commentsCount: { type: 'integer' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
          required: ['_id','author','createdAt','updatedAt']
        },
        CommunityComment: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            postId: { type: 'string' },
            author: { $ref: '#/components/schemas/CommunityAuthor' },
            text: { type: 'string' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
          required: ['_id','postId','author','text','createdAt','updatedAt']
        },
        Conversation: {
          type: 'object',
          properties: {
            _id: { type: 'string', description: 'Conversation ID' },
            type: { type: 'string', enum: ['solo', 'group'] },
            memberIds: { type: 'array', items: { type: 'string' } },
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
            senderId: { type: 'string' },
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

