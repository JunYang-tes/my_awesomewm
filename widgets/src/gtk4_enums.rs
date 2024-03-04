pub mod orientation {
    use gtk4::Orientation;
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
pub mod fit {
    use gtk4::ContentFit;
    pub fn from_num(i: u32) -> ContentFit {
        match i {
            0 => ContentFit::Fill,
            1 => ContentFit::Contain,
            2 => ContentFit::Cover,
            _ => ContentFit::ScaleDown,
        }
    }
    pub fn to_num(fit: ContentFit) -> u32 {
        match fit {
            ContentFit::Fill => 0,
            ContentFit::Contain => 1,
            ContentFit::Cover => 2,
            _ => 3,
        }
    }
}
