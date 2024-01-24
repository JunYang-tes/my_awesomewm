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
pub mod selection_mode {
    use gtk::SelectionMode;

    pub fn from_num(i: i32) -> SelectionMode {
        match i {
            0 => SelectionMode::None,
            1 => SelectionMode::Single,
            2 => SelectionMode::Browse,
            3 => SelectionMode::Multiple,
            i => SelectionMode::__Unknown(i),
        }
    }
    pub fn to_num(i: SelectionMode) -> i32 {
        match i {
            SelectionMode::None => 0,
            SelectionMode::Single => 1,
            SelectionMode::Browse => 2,
            SelectionMode::Multiple => 3,
            SelectionMode::__Unknown(i) => i,
            _ => panic!("Unknown selection mode"),
        }
    }
}

pub mod position_type {
    use gtk::PositionType;
    pub fn from_num(i: i32) -> PositionType {
        match i {
            0 => PositionType::Left,
            1 => PositionType::Right,
            2 => PositionType::Top,
            3 => PositionType::Bottom,
            i => PositionType::__Unknown(i),
        }
    }
}

pub mod orientation {
    use gtk::Orientation;
    pub fn from_num(i: i32) -> Orientation {
        match i {
            0 => Orientation::Horizontal,
            1 => Orientation::Vertical,
            i => Orientation::__Unknown(i),
        }
    }
    pub fn to_num(i: Orientation) -> i32 {
        match i {
            Orientation::Horizontal => 0,
            Orientation::Vertical => 1,
            Orientation::__Unknown(i) => i,
            _ => panic!("Unknown Orientation"),
        }
    }
}
