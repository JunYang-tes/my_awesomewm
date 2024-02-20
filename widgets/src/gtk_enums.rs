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
pub mod align {
    use gtk::Align;
    pub fn from_num(i: i32) -> Align {
        match i {
            0 => Align::Fill,
            1 => Align::Start,
            2 => Align::End,
            3 => Align::Center,
            4 => Align::Baseline,
            i => Align::__Unknown(i),
        }
    }
    pub fn to_num(i: Align) -> i32 {
        match i {
            Align::Fill => 0,
            Align::Start => 1,
            Align::End => 2,
            Align::Center => 3,
            Align::Baseline => 4,
            Align::__Unknown(i) => i,
            _ => panic!("Unknown Align"),
        }
    }
}
pub mod window_type_hint {
    use gtk::gdk::WindowTypeHint;
    pub fn from_num(i: i32) -> WindowTypeHint {
        match i {
            0 => WindowTypeHint::Normal,
            1 => WindowTypeHint::Dialog,
            2 => WindowTypeHint::Menu,
            3 => WindowTypeHint::Toolbar,
            4 => WindowTypeHint::Splashscreen,
            5 => WindowTypeHint::Utility,
            6 => WindowTypeHint::Dock,
            7 => WindowTypeHint::Desktop,
            8 => WindowTypeHint::DropdownMenu,
            9 => WindowTypeHint::PopupMenu,
            10 => WindowTypeHint::Tooltip,
            11 => WindowTypeHint::Notification,
            12 => WindowTypeHint::Combo,
            13 => WindowTypeHint::Dnd,
            i => WindowTypeHint::__Unknown(i),
        }
    }
    pub fn to_num(i: WindowTypeHint) -> i32 {
        match i {
            WindowTypeHint::Normal => 0,
            WindowTypeHint::Dialog => 1,
            WindowTypeHint::Menu => 2,
            WindowTypeHint::Toolbar => 3,
            WindowTypeHint::Splashscreen => 4,
            WindowTypeHint::Utility => 5,
            WindowTypeHint::Dock => 6,
            WindowTypeHint::Desktop => 7,
            WindowTypeHint::DropdownMenu => 8,
            WindowTypeHint::PopupMenu => 9,
            WindowTypeHint::Tooltip => 10,
            WindowTypeHint::Notification => 11,
            WindowTypeHint::Combo => 12,
            WindowTypeHint::Dnd => 13,
            WindowTypeHint::__Unknown(i) => i,
            _ => panic!("Unknown window type hint"),
        }
    }
}
