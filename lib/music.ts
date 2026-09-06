export type MusicRoleName = 'musician' | 'band_leader' | 'music_leader';

export type MusicRole = {
  user_id: string;
  role: MusicRoleName;
  created_at: string;
};

export type AssignmentConfirmationStatus = 'pending' | 'confirmed' | 'declined';

export type Profile = {
  user_id: string;
  display_name: string;
  email: string | null;
  phone: string | null;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
};

export type Band = {
  id: string;
  name: string;
  description: string | null;
  active: boolean;
  created_at: string;
  updated_at: string;
};

export type BandMembership = {
  band_id: string;
  user_id: string;
  is_leader: boolean;
  created_at: string;
};

export type Service = {
  id: string;
  title: string;
  service_date: string;
  starts_at: string;
  ends_at: string | null;
  service_type: string;
  status: 'draft' | 'scheduled' | 'cancelled' | 'completed';
  notes: string | null;
  created_at: string;
  updated_at: string;
};

export type ServiceAssignment = {
  id: string;
  service_id: string;
  user_id: string;
  responsibility: string;
  assignment_status: 'draft' | 'active' | 'cancelled';
  confirmation_status: AssignmentConfirmationStatus;
  notes: string | null;
  created_at: string;
  updated_at: string;
};

export type MusicSong = {
  id: string;
  title: string;
  artist: string | null;
  active: boolean;
  default_key: string | null;
  bpm: number | null;
  ccli_reference: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
};

export type MusicSetlist = {
  id: string;
  service_id: string;
  status: 'draft' | 'published';
  notes: string | null;
  created_at: string;
  updated_at: string;
};

export type MusicSetlistItem = {
  id: string;
  setlist_id: string;
  song_id: string;
  position: number;
  key_override: string | null;
  arrangement: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
};

export type MusicResource = {
  id: string;
  title: string;
  resource_type: 'audio' | 'chart' | 'lyrics' | 'link' | 'note';
  url: string | null;
  body: string | null;
  song_id: string | null;
  service_id: string | null;
  active: boolean;
  created_at: string;
  updated_at: string;
};

export type MusicDevelopment = {
  user_id: string;
  status: 'trainee' | 'developing' | 'competent' | 'leader_ready';
  skill: string | null;
  mentor_user_id: string | null;
  notes: string | null;
  updated_at: string;
};