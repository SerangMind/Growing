//
//  ContentView.swift
//  for Growing
//

import SwiftUI
import CoreData
import Alamofire
import SSSwiftUIGIFView

struct ChatDetail: Identifiable {
    
    var id: Int32
    var timestamp: Date = Date()
    var imageName: String = ""
    var message: String
    var userName: String
}


struct ContentView: View {
  
    @State var isCamera: Bool = false
    @State var image: Image? = nil
    @State var showCaptureImageView: Bool = false
  
    @State private var typingMessage: String = ""
    @State var isLastScroll: Bool = false
    
    @State var isImage: Bool = false
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ChatData.id, ascending: true)
        ],
        predicate: nil
    )

    private var items: FetchedResults<ChatData> // Generic
    
//    @State var chatDetails: Array<ChatDetail> = [
//        ChatDetail( id: 1, message: "Really love your most recent photo. I’ve been trying to capture the same thing for a few months and would love some tips!", userName: "G#" ),
//        ChatDetail( id: 2, message: "A fast 50mm like f1.8 would help with the bokeh. I’ve been using primes as they tend to get a bit sharper images.", userName: "girl1" ),
//        ChatDetail( id: 3, message: "Thank you! That was very helpful!", userName: "G#" )
//    ]
    
//    @State var chatDetails: Array<ChatDetail> = {
//        var chats: [ChatDetail] = []
//        for i in 0...items.count-1 {
//            chats.append( ChatDetail( id: items[i].id, message: items[i].message!, userName: items[i].userName! ) )
//        }
//        return chats
//    }()
    
    @State var chatDetails: Array<ChatDetail> = []

    init() {
        eventCheck( "init" )
    }

    private func eventCheck(_ eventName: String ) {
        
        print( "\(eventName) - chatDetails.count: \(chatDetails.count), items.count:\(items.count)")
    }

    private func load() {

        if chatDetails.count == 0 && items.count > 0 {
            for i in 0...items.count-1 {
                chatDetails.append( ChatDetail( id: items[i].id, message: items[i].message!, userName: items[i].userName! ) )
            }
        }
        eventCheck( "load" )
    }
    
    private func save( imgageName: String, message: String, userName: String ) {
        
        let context = PersistenceController.shared.container.viewContext
        let newChatData = ChatData(context: context)
    
        let chatData: ChatDetail = {
            let lastId: Int32! = items.last?.id ?? 0
            var chat: ChatDetail = ChatDetail( id: lastId + 1, message: message, userName: userName )
            chat.imageName = imgageName
            return chat
        }()
        
        newChatData.id = chatData.id
        newChatData.timestamp = chatData.timestamp
        newChatData.imageName = chatData.imageName
        newChatData.message = chatData.message
        newChatData.userName = chatData.userName
                
        //PersistenceController.shared.save()
        PersistenceController.shared.saveContext()
        
        chatDetails.append( chatData )
        //print( chatData )
        eventCheck( "Saved" )
    }
    
    private func addImage() {
        
        isImage = true
        save( imgageName: "apple", message: "이 이미지는 뭐예요?", userName: "G#" )
    }
    
    private func delete() {
        
        let context = PersistenceController.shared.container.viewContext
        
        if chatDetails.count > 0 {
            chatDetails.removeLast()
        }
        
        if items.count > 0 {
            context.delete( items[items.count - 1] )
            
            PersistenceController.shared.saveContext()
        }
        
        print( "Deleted - chatDetails.count: \(chatDetails.count), items.count:\(items.count)")
    }
    
    private func getGrowingMessage( imageName: String, query: String, userName: String ) {

        let urlString = "http://54.95.55.233/pingpong?query=\(query)&sessionId=\(userName)"
        let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: encodedString)!

        if imageName == "" {
            AF.request( url, method: .post )
            .responseString { response in
                
                let result = response.value!
                print( "getGrowingMessage: \(query) -> \(result)" )
            
                save( imgageName: imageName, message: result, userName: "G#" )
                typingMessage = ""
                isLastScroll = true
                
            }
            
        } else {
            
        }
    }
    
    private func sendMessage() {
        //chatHelper.sendMessage(Message(content: typingMessage, user: DataSource.secondUser))

        if typingMessage != "" {
            let imageName = ""
            let userName = "girl1"
            isLastScroll = false
            save( imgageName: imageName, message: typingMessage, userName: userName )
            getGrowingMessage( imageName: imageName, query: typingMessage, userName: userName )
        }
    }
    
    var body: some View {
          
      GeometryReader { gp in
          
          let buttonHeight: CGFloat = 50
          let screenWidth: CGFloat = gp.size.width
          let screenHeight: CGFloat = gp.size.height - buttonHeight
          let cameraHeight: CGFloat = screenHeight * 0.4
          let chatHeight: CGFloat = screenHeight * 0.6
          
          //let _ = print( "cameraHeight: \(cameraHeight)")
          
          ZStack {
              
              VStack(spacing: 0) {
                  
                  //if !isImage && chatDetails.count == 0 && items.count == 0 {
                  if !isImage && items.count == 0 {

                      VStack {
//                          Image(uiImage: #imageLiteral(resourceName: "Growing.png" ) )
//                              .resizable()
//                              .aspectRatio(contentMode: .fit)
                          SwiftUIGIFPlayerView(gifName: "GrowingIntro")
                          
                      }
                      .frame( width: screenWidth, height: screenHeight )
                      .onChange( of: image ) { _ in
                          eventCheck("onChange - Intro")
                          addImage()
                      }
                      
                  } else {
 
                      if isImage && cameraHeight > 0 {
                          
                          VStack {
                              
                              image?.resizable()
                                  .resizable()
                                  .aspectRatio(contentMode: .fit)
                          }
                          .frame( width: screenWidth, height: cameraHeight )
                          .onChange( of: image ) { _ in
                              eventCheck("onChange - Image")
                              addImage()
                          }
                        
                      }

                      if chatHeight > 0 {
                          
                          VStack {
                              
                              ChatDetailView( chatDetails: chatDetails, title: "Growing" )
                          }
                          .frame( width: screenWidth, height: ( isImage ? chatHeight : screenHeight ) )
                          .onAppear {
                              eventCheck( "onAppear - Chat" )
                              load()
                          }
                          .onChange( of: image ) { _ in
                              eventCheck( "onChange - Chat" )
                              addImage()
                          }
                      }
                      
                  }
                  
                  VStack {
                      
                        HStack(spacing:5) {
                          
                            Button(action: {
                              
                              self.isCamera = true
                              self.showCaptureImageView.toggle()

                            })  {
                              Image(systemName: "camera.fill")
                            }

                            Button(action: {
                              
                              self.isCamera = false
                              self.showCaptureImageView.toggle()

                            })  {
                              Image(systemName: "photo.fill")
                            }
                              
                            TextField( "Message...", text: $typingMessage )
                                  .textFieldStyle(RoundedBorderTextFieldStyle())
                                  .frame(minHeight: CGFloat(30))
                                  
                            Button(action: sendMessage ) {
                               //Image(systemName: "square.and.arrow.up")
                               Image(systemName: "paperplane.circle.fill")
                                   .resizable()
                                   .aspectRatio(contentMode: .fit)
                                   .frame(width: 21, height: 21)
                            }

                            if ( chatDetails.count > 0 ) && ( items.count > 0 ) {
                                Button(action: delete ) {
                                    Image(systemName: "trash.fill")
                                }
                            }
                          
                        }
                        .frame(minHeight: buttonHeight).padding(15)
                      
                  }
                  .frame(width: gp.size.width, height: buttonHeight )
                  //.navigationBarTitle( Text(navTitle), displayMode: .inline )
                  //.padding(.bottom, keyboard.currentHeight )
                  //.edgesIgnoringSafeArea( keyboard.currentHeight == 0.0 ? .leading: .bottom )
                  //.edgesIgnoringSafeArea( .bottom )
                  .padding(0)
              }
              
              if (showCaptureImageView) {
                  
                  CaptureImageView(isCamera: isCamera, isShown: $showCaptureImageView, image: $image)
                  //.navigationTitle("Camera")

              }

          }
          
      }
      
    }
    
}


struct ChatDetailView: View {
    
    var chatDetails: [ChatDetail]
    var title: String = ""
    
    var body: some View {
        
        if chatDetails.count > 0 {
                
            ScrollViewReader { scrollView in

                ScrollView(.vertical) {
                //List {
                    VStack( spacing: 0 ) {
                        
                        ForEach( chatDetails ) { chat in
                            ChatDetailItemView( chat: chat )
                                .id(chat.id)
                            //let _ = print( "Scroll id: \(chat.id)")
                         }
                        
                    }

                }
                .onAppear {
                    print( "onAppear - last.id:\(chatDetails.last?.id ?? 0)" )
                    withAnimation {
                        scrollView.scrollTo( (chatDetails.last?.id ?? 0)  )
                    }
                }
                .onChange( of: chatDetails.count ) { _ in
                    print( "onChange - last.id:\(chatDetails.last?.id ?? 0)" )
                    withAnimation {
                        scrollView.scrollTo( (chatDetails.last?.id ?? 0) + 1 )
                    }
                }
                
            }
            
        } else {
            
//            Image(uiImage: #imageLiteral(resourceName: "Growing.png" ) )
//                .resizable()
//                .aspectRatio(contentMode: .fit)

        }

    }
}


struct ChatDetailItemView: View {
    
    var chat: ChatDetail
    
    var body: some View {
        
        let isGrowing: Bool = ( chat.userName == "G#" )
        
        //VStack( alignment: ( isGrowing ? .leading : .trailing ), spacing: 0 ) {

            HStack( alignment: .bottom, spacing: 10 ) {
                
                if isGrowing {
                    Image(uiImage: #imageLiteral(resourceName: "Growing.png" ) )
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:40, height:45)
                        .clipShape(Circle())
                    
                } else {
                    Spacer()
                }
                
                Text(chat.message)
                    .padding(10)
                    .foregroundColor(isGrowing ? Color.white : Color.black)
                    .background(isGrowing ? Color.blue : Color(UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)))
                    .cornerRadius(10)
                
                if !isGrowing {
                    Image(uiImage: #imageLiteral(resourceName: "\(chat.userName).png" ) )
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:30, height:30)
                        .clipShape(Circle())
                    
                } else {
                    Spacer()
                }
                
            }
            //.padding(.horizontal, 10 )
            .padding(10)

        //}

    }
    
}
