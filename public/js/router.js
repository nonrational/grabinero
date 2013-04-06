// Meteor.Router.add({
//   '/': 'index',
//   '/editor': 'editor',
//   '/leaderboard': 'leaderboard'
// });

// Meteor.Router.filters({
//   'loggedIn': function(page) {
//     console.log("hi");
//     if (Meteor.user()) {
//       if(page == 'index') {
//         Meteor.Router.to('/profile');
//         return 'profile';
//       } else {
//         return page;
//       }
//     } else {
//       return 'index';
//     }
//   }
// });

// Meteor.Router.filter('loggedIn');
