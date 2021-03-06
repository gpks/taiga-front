###
# Copyright (C) 2014-2015 Taiga Agile LLC <taiga@taiga.io>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# File: subscriptions.controller.spec.coffee
###

describe "HistorySection", ->
    provide = null
    controller = null
    mocks = {}

    _mockTgResources = () ->
        mocks.tgResources = {
            history: {
                get: sinon.stub()
                deleteComment: sinon.stub()
                undeleteComment: sinon.stub()
                editComment: sinon.stub()
            }
        }

        provide.value "$tgResources", mocks.tgResources

    _mockTgRepo = () ->
        mocks.tgRepo = {
            save: sinon.stub()
        }

        provide.value "$tgRepo", mocks.tgRepo

    _mocktgStorage = () ->
        mocks.tgStorage = {
            get: sinon.stub()
            set: sinon.stub()
        }
        provide.value "$tgStorage", mocks.tgStorage

    _mocks = () ->
        module ($provide) ->
            provide = $provide
            _mockTgResources()
            _mockTgRepo()
            _mocktgStorage()
            return null

    beforeEach ->
        module "taigaHistory"

        _mocks()

        inject ($controller) ->
            controller = $controller
        promise = mocks.tgResources.history.get.promise().resolve()

    it "load historic", (done) ->
        historyCtrl = controller "HistorySection"

        historyCtrl._getComments = sinon.stub()
        historyCtrl._getActivities = sinon.stub()

        name = "name"
        id = 4

        promise = mocks.tgResources.history.get.withArgs(name, id).promise().resolve()
        historyCtrl._loadHistory().then (data) ->
            expect(historyCtrl._getComments).have.been.calledWith(data)
            expect(historyCtrl._getActivities).have.been.calledWith(data)
            done()

    it "get Comments older first", () ->
        historyCtrl = controller "HistorySection"

        comments = ['comment3', 'comment2', 'comment1']
        historyCtrl.reverse = false

        historyCtrl._getComments(comments)
        expect(historyCtrl.comments).to.be.eql(['comment3', 'comment2', 'comment1'])
        expect(historyCtrl.commentsNum).to.be.equal(3)

    it "get Comments newer first", () ->
        historyCtrl = controller "HistorySection"

        comments = ['comment3', 'comment2', 'comment1']
        historyCtrl.reverse = true

        historyCtrl._getComments(comments)
        expect(historyCtrl.comments).to.be.eql(['comment1', 'comment2', 'comment3'])
        expect(historyCtrl.commentsNum).to.be.equal(3)

    it "get activities", () ->
        historyCtrl = controller "HistorySection"
        activities = {
            'activity1': {
                'values_diff': {"k1": [0, 1]}
            },
            'activity2': {
                'values_diff': {"k2": [0, 1]}
            },
            'activity3': {
                'values_diff': {"k3": [0, 1]}
            },
        }

        historyCtrl._getActivities(activities)

        historyCtrl.activities = activities
        expect(historyCtrl.activitiesNum).to.be.equal(3)

    it "on active history tab", () ->
        historyCtrl = controller "HistorySection"
        active = true
        historyCtrl.onActiveHistoryTab(active)
        expect(historyCtrl.viewComments).to.be.true

    it "on inactive history tab", () ->
        historyCtrl = controller "HistorySection"
        active = false
        historyCtrl.onActiveHistoryTab(active)
        expect(historyCtrl.viewComments).to.be.false

    it "delete comment", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl._loadHistory = sinon.stub()

        historyCtrl.name = "type"
        historyCtrl.id = 1

        type = historyCtrl.name
        objectId = historyCtrl.id
        commentId = 7

        promise = mocks.tgResources.history.deleteComment.withArgs(type, objectId, commentId).promise().resolve()

        historyCtrl.deleting = true
        historyCtrl.deleteComment(commentId).then () ->
            expect(historyCtrl._loadHistory).have.been.called
            expect(historyCtrl.deleting).to.be.false

    it "edit comment", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl._loadHistory = sinon.stub()

        historyCtrl.name = "type"
        historyCtrl.id = 1
        activityId = 7
        comment = "blablabla"

        type = historyCtrl.name
        objectId = historyCtrl.id
        commentId = activityId

        promise = mocks.tgResources.history.editComment.withArgs(type, objectId, activityId, comment).promise().resolve()

        historyCtrl.editing = true
        historyCtrl.editComment(commentId, comment).then () ->
            expect(historyCtrl._loadHistory).has.been.called
            expect(historyCtrl.editing).to.be.false

    it "restore comment", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl._loadHistory = sinon.stub()

        historyCtrl.name = "type"
        historyCtrl.id = 1
        activityId = 7

        type = historyCtrl.name
        objectId = historyCtrl.id
        commentId = activityId

        promise = mocks.tgResources.history.undeleteComment.withArgs(type, objectId, activityId).promise().resolve()

        historyCtrl.editing = true
        historyCtrl.restoreDeletedComment(commentId).then () ->
            expect(historyCtrl._loadHistory).has.been.called
            expect(historyCtrl.editing).to.be.false

    it "add comment", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl._loadHistory = sinon.stub()

        historyCtrl.type = "type"
        type = historyCtrl.type
        historyCtrl.loading = true

        promise = mocks.tgRepo.save.withArgs(type).promise().resolve()

        historyCtrl.addComment().then () ->
            expect(historyCtrl._loadHistory).has.been.called
            expect(historyCtrl.loading).to.be.false

    it "order comments", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl._loadHistory = sinon.stub()

        historyCtrl.reverse = false

        historyCtrl.onOrderComments()
        expect(historyCtrl.reverse).to.be.true
        expect(mocks.tgStorage.set).has.been.calledWith("orderComments", historyCtrl.reverse)
        expect(historyCtrl._loadHistory).has.been.called
