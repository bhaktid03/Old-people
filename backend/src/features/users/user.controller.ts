import { Request, Response } from "express";
import { createUser, deleteUser, getUserById, listUsers, updateUser } from "./user.repo.js";
import { UserDoc } from "./user.types.js";

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           description: User ID
 *         phone:
 *           type: string
 *         email:
 *           type: string
 *           format: email
 *         displayName:
 *           type: string
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *       required: [ _id, createdAt, updatedAt ]
 */

/**
 * @swagger
 * /api/v1/users:
 *   get:
 *     summary: List users
 *     tags: [Users]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 50
 *     responses:
 *       200:
 *         description: List of users
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 */
export async function listUsersHandler(req: Request, res: Response) {
  const limit = req.query.limit ? Math.min(Number(req.query.limit), 100) : 50;
  const users = await listUsers(limit);
  res.json({ data: users });
}

/**
 * @swagger
 * /api/v1/users:
 *   post:
 *     summary: Create user
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               _id:
 *                 type: string
 *               phone:
 *                 type: string
 *               email:
 *                 type: string
 *                 format: email
 *               displayName:
 *                 type: string
 *             required: [ _id ]
 *     responses:
 *       201:
 *         description: Created user
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 */
export async function createUserHandler(req: Request, res: Response) {
  const { _id, phone, email, displayName } = req.body as Partial<UserDoc>;
  if (!_id || typeof _id !== "string") {
    return res.status(400).json({ ok: false, error: "_id is required" });
  }
  const user = await createUser({ _id, phone, email, displayName } as any);
  res.status(201).json(user);
}

/**
 * @swagger
 * /api/v1/users/{id}:
 *   get:
 *     summary: Get a user by ID
 *     tags: [Users]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
  *           type: string
  *           example: +919876543210
  *           description: Profile _id (E.164 phone)
 *     responses:
 *       200:
 *         description: User found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       404:
 *         description: Not found
 */
export async function getUserHandler(req: Request, res: Response) {
  const id = req.params.id;
  const user = await getUserById(id);
  if (!user) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(user);
}

/**
 * @swagger
 * /api/v1/users/{id}:
 *   put:
 *     summary: Update a user
 *     tags: [Users]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Updated user
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       404:
 *         description: Not found
 */
export async function updateUserHandler(req: Request, res: Response) {
  const id = req.params.id;
  const updated = await updateUser(id, req.body as Partial<UserDoc>);
  if (!updated) return res.status(404).json({ ok: false, error: "Not found" });
  res.json(updated);
}

/**
 * @swagger
 * /api/v1/users/{id}:
 *   delete:
 *     summary: Delete a user
 *     tags: [Users]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       204:
 *         description: Deleted
 *       404:
 *         description: Not found
 */
export async function deleteUserHandler(req: Request, res: Response) {
  const id = req.params.id;
  const ok = await deleteUser(id);
  if (!ok) return res.status(404).json({ ok: false, error: "Not found" });
  res.status(204).send();
}


