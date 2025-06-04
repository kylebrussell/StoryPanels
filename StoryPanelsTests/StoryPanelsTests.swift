//
//  StoryPanelsTests.swift
//  StoryPanelsTests
//
//  Created by Kyle Russell on 5/22/25.
//

import Testing
@testable import StoryPanels

struct StoryPanelsTests {

    @Test func comicInitializesPanels() {
        let comic = Comic(layout: .threePanel)
        #expect(comic.panels.count == 3)
    }

}
