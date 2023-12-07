pub enum Node {
    Box(Vec<Node>),
    Img,
    Text,
}
