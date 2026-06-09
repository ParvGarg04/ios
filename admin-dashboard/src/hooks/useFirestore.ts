import {
  collection, query, where, orderBy, limit,
  getDocs, doc, updateDoc, addDoc, deleteDoc,
  Timestamp, onSnapshot, QueryConstraint,
} from 'firebase/firestore';
import { db } from '../firebase';
import { TaskItem, TaskSubmission, WaterLog, UserProfile, ReviewItem, DashboardStats } from '../types';

// ─── helpers ───────────────────────────────────────────────
function tsToDate(val: any): Date {
  if (!val) return new Date();
  if (val instanceof Timestamp) return val.toDate();
  if (val?.seconds) return new Date(val.seconds * 1000);
  return new Date(val);
}

function docToSubmission(d: any): TaskSubmission {
  const data = d.data();
  return {
    id: d.id,
    submissionId:      data.submissionId ?? d.id,
    taskId:            data.taskId ?? '',
    userId:            data.userId ?? '',
    taskTitle:         data.taskTitle ?? 'Untitled',
    imageURL:          data.imageURL ?? undefined,
    note:              data.note ?? undefined,
    submittedAt:       tsToDate(data.submittedAt),
    verificationStatus: data.verificationStatus ?? 'pending_review',
    adminComment:      data.adminComment ?? undefined,
    verifiedAt:        data.verifiedAt ? tsToDate(data.verifiedAt) : undefined,
  };
}

function docToWaterLog(d: any): WaterLog {
  const data = d.data();
  return {
    id:         d.id,
    logId:      data.logId ?? d.id,
    userId:     data.userId ?? '',
    imageURL:   data.imageURL ?? undefined,
    note:       data.note ?? undefined,
    uploadedAt: tsToDate(data.uploadedAt),
    status:     data.status ?? 'pending_review',
    verifiedAt: data.verifiedAt ? tsToDate(data.verifiedAt) : undefined,
    adminComment: data.adminComment ?? undefined,
  };
}

function docToTask(d: any): TaskItem {
  const data = d.data();
  return {
    id:                   d.id,
    taskId:               data.taskId ?? d.id,
    userId:               data.userId ?? '',
    title:                data.title ?? '',
    description:          data.description ?? '',
    type:                 data.type ?? 'simple',
    dueTime:              data.dueTime ? tsToDate(data.dueTime) : undefined,
    repeatInterval:       data.repeatInterval ?? 'none',
    customRepeatMinutes:  data.customRepeatMinutes ?? undefined,
    priority:             data.priority ?? 'normal',
    requiresProof:        data.requiresProof ?? false,
    isActive:             data.isActive ?? true,
    createdAt:            tsToDate(data.createdAt),
    assignedBy:           data.assignedBy ?? '',
  };
}

function docToUser(d: any): UserProfile {
  const data = d.data();
  return {
    id:       d.id,
    name:     data.name ?? 'Member',
    email:    data.email ?? '',
    role:     data.role ?? 'member',
    streak:   data.streak ?? 0,
    createdAt: tsToDate(data.createdAt),
  };
}

// ─── Submissions ────────────────────────────────────────────
export async function fetchAllSubmissions(): Promise<TaskSubmission[]> {
  const snap = await getDocs(
    query(collection(db, 'taskSubmissions'), orderBy('submittedAt', 'desc'), limit(300))
  );
  return snap.docs.map(docToSubmission);
}

export async function fetchPendingSubmissions(): Promise<TaskSubmission[]> {
  const snap = await getDocs(
    query(
      collection(db, 'taskSubmissions'),
      where('verificationStatus', '==', 'pending_review'),
      orderBy('submittedAt', 'desc')
    )
  );
  return snap.docs.map(docToSubmission);
}

export async function reviewSubmission(
  submissionId: string,
  status: 'verified' | 'rejected',
  comment: string
): Promise<void> {
  await updateDoc(doc(db, 'taskSubmissions', submissionId), {
    verificationStatus: status,
    adminComment: comment || null,
    verifiedAt: Timestamp.now(),
  });
}

// ─── Water Logs ─────────────────────────────────────────────
export async function fetchAllWaterLogs(): Promise<WaterLog[]> {
  const snap = await getDocs(
    query(collection(db, 'waterLogs'), orderBy('uploadedAt', 'desc'), limit(300))
  );
  return snap.docs.map(docToWaterLog);
}

export async function fetchPendingWaterLogs(): Promise<WaterLog[]> {
  const snap = await getDocs(
    query(
      collection(db, 'waterLogs'),
      where('status', '==', 'pending_review'),
      orderBy('uploadedAt', 'desc')
    )
  );
  return snap.docs.map(docToWaterLog);
}

export async function reviewWaterLog(
  logId: string,
  status: 'verified' | 'rejected',
  comment: string
): Promise<void> {
  await updateDoc(doc(db, 'waterLogs', logId), {
    status,
    adminComment: comment || null,
    verifiedAt: Timestamp.now(),
  });
}

// ─── Combined pending reviews ────────────────────────────────
export async function fetchPendingReviews(
  userMap: Record<string, string>
): Promise<ReviewItem[]> {
  const [subs, logs] = await Promise.all([
    fetchPendingSubmissions(),
    fetchPendingWaterLogs(),
  ]);

  const subItems: ReviewItem[] = subs.map(s => ({
    id:          s.id,
    kind:        'task',
    title:       s.taskTitle,
    userId:      s.userId,
    userName:    userMap[s.userId] ?? s.userId,
    imageURL:    s.imageURL,
    note:        s.note,
    submittedAt: s.submittedAt,
    status:      s.verificationStatus,
    adminComment: s.adminComment,
    taskId:      s.submissionId,
  }));

  const waterItems: ReviewItem[] = logs.map(l => ({
    id:          l.id,
    kind:        'water',
    title:       'Hydration Log',
    userId:      l.userId,
    userName:    userMap[l.userId] ?? l.userId,
    imageURL:    l.imageURL,
    note:        l.note,
    submittedAt: l.uploadedAt,
    status:      l.status,
    adminComment: l.adminComment,
    logId:       l.logId,
  }));

  return [...subItems, ...waterItems].sort(
    (a, b) => b.submittedAt.getTime() - a.submittedAt.getTime()
  );
}

// ─── Tasks ──────────────────────────────────────────────────
export async function fetchAllTasks(): Promise<TaskItem[]> {
  const snap = await getDocs(
    query(collection(db, 'tasks'), orderBy('createdAt', 'desc'))
  );
  return snap.docs.map(docToTask);
}

export async function createTask(task: Omit<TaskItem, 'id'>): Promise<string> {
  const ref = await addDoc(collection(db, 'tasks'), {
    ...task,
    createdAt: Timestamp.now(),
    dueTime: task.dueTime ? Timestamp.fromDate(task.dueTime) : null,
  });
  return ref.id;
}

export async function updateTask(taskId: string, updates: Partial<TaskItem>): Promise<void> {
  const data: any = { ...updates };
  if (updates.dueTime) data.dueTime = Timestamp.fromDate(updates.dueTime);
  await updateDoc(doc(db, 'tasks', taskId), data);
}

export async function deleteTask(taskId: string): Promise<void> {
  await updateDoc(doc(db, 'tasks', taskId), { isActive: false });
}

// ─── Users ──────────────────────────────────────────────────
export async function fetchAllMembers(): Promise<UserProfile[]> {
  const snap = await getDocs(
    query(collection(db, 'users'), where('role', '==', 'member'))
  );
  return snap.docs.map(docToUser);
}

// ─── Dashboard Stats ─────────────────────────────────────────
export async function fetchDashboardStats(): Promise<DashboardStats> {
  const now     = new Date();
  const today   = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const weekAgo = new Date(today.getTime() - 7 * 86400000);

  const [members, allSubs, waterToday] = await Promise.all([
    fetchAllMembers(),
    fetchAllSubmissions(),
    getDocs(query(
      collection(db, 'waterLogs'),
      where('uploadedAt', '>=', Timestamp.fromDate(today))
    )),
  ]);

  const pendingCount = allSubs.filter(s => s.verificationStatus === 'pending_review').length
    + (await fetchPendingWaterLogs()).length;

  const weekSubs = allSubs.filter(s => s.submittedAt >= weekAgo);
  const verified = weekSubs.filter(s => s.verificationStatus === 'verified').length;
  const missed   = weekSubs.filter(s => s.verificationStatus === 'rejected').length;
  const rate     = weekSubs.length > 0 ? Math.round((verified / weekSubs.length) * 100) : 0;

  return {
    totalMembers:           members.length,
    pendingReviews:         pendingCount,
    todayCompletionRate:    rate,
    todayWaterLogs:         waterToday.size,
    weeklyTasksCompleted:   verified,
    weeklyTasksMissed:      missed,
  };
}
