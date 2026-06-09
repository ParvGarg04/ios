export type UserRole = 'member' | 'admin';
export type VerificationStatus = 'pending_review' | 'verified' | 'rejected';
export type TaskType = 'simple' | 'proofRequired';
export type TaskPriority = 'normal' | 'important' | 'urgent';
export type RepeatInterval = 'none' | 'daily' | 'weekly' | 'hourly' | 'custom';

export interface UserProfile {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  streak: number;
  lastActiveDate?: Date;
  createdAt: Date;
}

export interface TaskItem {
  id: string;
  taskId: string;
  userId: string;
  title: string;
  description: string;
  type: TaskType;
  dueTime?: Date;
  repeatInterval: RepeatInterval;
  customRepeatMinutes?: number;
  priority: TaskPriority;
  requiresProof: boolean;
  isActive: boolean;
  createdAt: Date;
  assignedBy: string;
}

export interface TaskSubmission {
  id: string;
  submissionId: string;
  taskId: string;
  userId: string;
  taskTitle: string;
  imageURL?: string;
  note?: string;
  submittedAt: Date;
  verificationStatus: VerificationStatus;
  adminComment?: string;
  verifiedAt?: Date;
}

export interface WaterLog {
  id: string;
  logId: string;
  userId: string;
  imageURL?: string;
  note?: string;
  uploadedAt: Date;
  status: VerificationStatus;
  verifiedAt?: Date;
  adminComment?: string;
}

export interface ReviewItem {
  id: string;
  kind: 'task' | 'water';
  title: string;
  userId: string;
  userName?: string;
  imageURL?: string;
  note?: string;
  submittedAt: Date;
  status: VerificationStatus;
  adminComment?: string;
  taskId?: string;
  logId?: string;
}

export interface DashboardStats {
  totalMembers: number;
  pendingReviews: number;
  todayCompletionRate: number;
  todayWaterLogs: number;
  weeklyTasksCompleted: number;
  weeklyTasksMissed: number;
}
