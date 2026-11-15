import waiting from "~/components/screens/waiting.vue"
import opening from "~/components/screens/opening.vue"
import problems from "~/components/screens/problems.vue"
import lobby from "~/components/screens/lobby.vue"
import problems_tutorial from "~/components/screens/problems_tutorial.vue"
import details from "~/components/screens/details.vue"
import details_tutorial from "~/components/screens/details_tutorial.vue"
import drawing_tutorial from "~/components/screens/drawing_tutorial.vue"
import drawing from "~/components/screens/drawing.vue"
import presentation from "~/components/screens/presentation.vue"
import presentation_tutorial from "~/components/screens/presentation_tutorial.vue"
import details2 from "~/components/screens/2.0_details.vue"
import details2_tutorial from "~/components/screens/2.0_details_tutorial.vue"
import drawing2 from "~/components/screens/2.0_drawing.vue"
import drawing2_tutorial from "~/components/screens/2.0_drawing_tutorial.vue"
import press_conference from "~/components/screens/press_conference.vue"
import press_conference_tutorial from "~/components/screens/press_conference_tutorial.vue"
import review_tutorial from "~/components/screens/review_tutorial.vue"
import review from "~/components/screens/review.vue"
import vote from "~/components/screens/vote.vue"
import results from "~/components/screens/results.vue"
import midway_cutscene from "~/components/screens/midway_cutscene.vue"

export const SCREENS = {
  "waiting": waiting,
  "opening": opening,
  "lobby": lobby,

  "problems": problems,
  "problems_tutorial": problems_tutorial,

  "details": details,
  "details_tutorial": details_tutorial,

  "drawing_tutorial": drawing_tutorial,
  "drawing": drawing,

  "presentation_tutorial": presentation_tutorial,
  "presentation": presentation,

  "review_tutorial": review_tutorial,
  "review": review,

  "2.0_details_tutorial": details2_tutorial,
  "2.0_details": details2,
  "2.0_drawing_tutorial": drawing2_tutorial,
  "2.0_drawing": drawing2,
  "midway_cutscene": midway_cutscene,

  "press_conference_tutorial": press_conference_tutorial,
  "press_conference": press_conference,

  "vote": vote,
  "results": results,
  "winner": results
}
