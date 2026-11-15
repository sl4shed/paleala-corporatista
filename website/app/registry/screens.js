import waiting from "~/components/screens/waiting.vue"
import opening from "~/components/screens/opening.vue"
import problems from "~/components/screens/problems.vue"
import lobby from "~/components/screens/lobby.vue"
import problems_tutorial from "~/components/screens/problems_tutorial.vue"
import details from "~/components/screens/details.vue"
import details_tutorial from "~/components/screens/details_tutorial.vue"
import drawing_tutorial from "~/components/screens/drawing_tutorial.vue"
import drawing from "~/components/screens/drawing.vue"

export const SCREENS = {
  "waiting": waiting,
  "opening": opening,
  "lobby": lobby,

  "problems": problems,
  "problems_tutorial": problems_tutorial,

  "details": details,
  "details_tutorial": details_tutorial,

  "drawing_tutorial": drawing_tutorial,
  "drawing": drawing
}
