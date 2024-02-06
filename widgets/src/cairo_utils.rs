use cairo::*;
pub fn get_surface_size(surface: &cairo::Surface) -> (i32, i32) {
    match surface.type_() {
        cairo::SurfaceType::Image => {
            let s = unsafe { cairo::ImageSurface::from_raw_none(surface.to_raw_none()).unwrap() };
            (s.width(), s.height())
        }

        _ => {
            panic!("Unsupported")
        }
    }
}
