import { Timestamp } from 'firebase/firestore';

type FirestoreDate = Timestamp | { seconds: number } | Date | undefined;

export function formatDate(value: FirestoreDate): string {
  if (!value) return '—';
  if (value instanceof Timestamp) {
    return value.toDate().toLocaleString();
  }
  if (value instanceof Date) {
    return value.toLocaleString();
  }
  if ('seconds' in value) {
    return new Date(value.seconds * 1000).toLocaleString();
  }
  return '—';
}

export function toTimestamp(dateString: string): Timestamp {
  return Timestamp.fromDate(new Date(dateString));
}
