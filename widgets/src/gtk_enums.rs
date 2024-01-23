pub mod justification {
    pub fn to_num(t: gtk::Justification) -> i32 {
        match t {
            gtk::Justification::Left => 0,
            gtk::Justification::Right => 1,
            gtk::Justification::Center => 2,
            gtk::Justification::Fill => 3,
            gtk::Justification::__Unknown(i) => i,
            _ => {
                panic!("Unknown enum")
            }
        }
    }
    pub fn from_num(i: i32) -> gtk::Justification {
        match i {
            0 => gtk::Justification::Left,
            1 => gtk::Justification::Right,
            2 => gtk::Justification::Center,
            3 => gtk::Justification::Fill,
            i => gtk::Justification::__Unknown(i),
        }
    }
}
pub mod wrap_mode {
    pub fn from_num(i: i32) -> pango::WrapMode {
        match i {
            0 => pango::WrapMode::Word,
            1 => pango::WrapMode::Char,
            2 => pango::WrapMode::WordChar,
            i => pango::WrapMode::__Unknown(i),
        }
    }
    pub fn to_num(i: pango::WrapMode) -> i32 {
        match i {
            pango::WrapMode::Word => 0,
            pango::WrapMode::Char => 1,
            pango::WrapMode::WordChar => 2,
            pango::WrapMode::__Unknown(i) => i,
            _ => -1,
        }
    }
}
