-- MySQL 8.0.18+。在自己新建的空练习库中执行，不包含 DROP/USE。
-- 全部表采用 RESTRICT/默认限制动作，避免删除资料时抹掉历史。
CREATE TABLE students (
  student_no VARCHAR(16) NOT NULL PRIMARY KEY,
  student_name VARCHAR(80) NOT NULL,
  department VARCHAR(80) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE clubs (
  club_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  club_name VARCHAR(80) NOT NULL,
  description TEXT NULL,
  organizer_no VARCHAR(16) NULL,
  CONSTRAINT fk_club_organizer FOREIGN KEY (organizer_no)
    REFERENCES students(student_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE memberships (
  attempt_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  student_no VARCHAR(16) NOT NULL,
  club_id BIGINT NOT NULL,
  state VARCHAR(12) NOT NULL,
  applied_at DATETIME(6) NOT NULL,
  handled_at DATETIME(6) NULL,
  joined_at DATETIME(6) NULL,
  left_at DATETIME(6) NULL,
  decision_note VARCHAR(255) NULL,
  open_slot TINYINT GENERATED ALWAYS AS
    (CASE WHEN state IN ('pending','active') THEN 1 ELSE NULL END) STORED,
  CONSTRAINT uq_membership_open UNIQUE (student_no, club_id, open_slot),
  CONSTRAINT fk_membership_student FOREIGN KEY (student_no)
    REFERENCES students(student_no),
  CONSTRAINT fk_membership_club FOREIGN KEY (club_id) REFERENCES clubs(club_id),
  CONSTRAINT ck_membership_state CHECK
    (state IN ('pending','active','rejected','withdrawn','left')),
  CONSTRAINT ck_membership_times CHECK
    ((handled_at IS NULL OR handled_at >= applied_at)
     AND (joined_at IS NULL OR joined_at >= applied_at)
     AND (left_at IS NULL OR (joined_at IS NOT NULL AND left_at > joined_at))),
  CONSTRAINT ck_membership_lifecycle CHECK (
    (state='pending' AND handled_at IS NULL AND joined_at IS NULL AND left_at IS NULL)
    OR (state IN ('rejected','withdrawn') AND handled_at IS NOT NULL
        AND joined_at IS NULL AND left_at IS NULL)
    OR (state='active' AND handled_at IS NOT NULL AND joined_at IS NOT NULL
        AND joined_at=handled_at AND left_at IS NULL)
    OR (state='left' AND handled_at IS NOT NULL AND joined_at IS NOT NULL
        AND joined_at=handled_at AND left_at IS NOT NULL)
  ),
  CONSTRAINT ck_rejection_reason CHECK
    (state <> 'rejected' OR (decision_note IS NOT NULL AND CHAR_LENGTH(TRIM(decision_note))>0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE events (
  event_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  club_id BIGINT NOT NULL,
  title VARCHAR(120) NOT NULL,
  starts_at DATETIME(6) NOT NULL,
  ends_at DATETIME(6) NOT NULL,
  opens_at DATETIME(6) NOT NULL,
  closes_at DATETIME(6) NOT NULL,
  capacity INT NOT NULL,
  state VARCHAR(12) NOT NULL DEFAULT 'published',
  CONSTRAINT fk_event_club FOREIGN KEY (club_id) REFERENCES clubs(club_id),
  CONSTRAINT ck_event_times CHECK
    (opens_at < closes_at AND closes_at <= starts_at AND starts_at < ends_at),
  CONSTRAINT ck_event_capacity CHECK (capacity > 0),
  CONSTRAINT ck_event_state CHECK (state IN ('published','cancelled'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE registrations (
  attempt_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  student_no VARCHAR(16) NOT NULL,
  event_id BIGINT NOT NULL,
  state VARCHAR(12) NOT NULL,
  requested_at DATETIME(6) NOT NULL,
  cancelled_at DATETIME(6) NULL,
  cancel_reason VARCHAR(120) NULL,
  active_slot TINYINT GENERATED ALWAYS AS
    (CASE WHEN state='confirmed' THEN 1 ELSE NULL END) STORED,
  CONSTRAINT uq_registration_active UNIQUE (student_no, event_id, active_slot),
  CONSTRAINT fk_registration_student FOREIGN KEY (student_no)
    REFERENCES students(student_no),
  CONSTRAINT fk_registration_event FOREIGN KEY (event_id) REFERENCES events(event_id),
  CONSTRAINT ck_registration_state CHECK (state IN ('confirmed','cancelled')),
  CONSTRAINT ck_registration_times CHECK (
    (state='confirmed' AND cancelled_at IS NULL)
    OR (state='cancelled' AND cancelled_at IS NOT NULL
        AND cancelled_at >= requested_at)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
