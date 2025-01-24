import SwiftUI

struct ProfileImageView: View {
    let imageData: Data?
    let size: CGFloat
    
    var body: some View {
        if let imageData = imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(.gray)
        }
    }
}

struct ProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ProfileImageView(imageData: nil, size: 50)
            ProfileImageView(imageData: nil, size: 100)
        }
    }
}
