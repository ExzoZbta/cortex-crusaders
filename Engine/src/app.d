/**
 * @file app.d
 * @brief Program entry point.
 */
import gameapplication;

/**
 * Application entry point.
 * Creates and runs the game application.
 */
void main()
{
	GameApplication app = GameApplication("D SDL Application");	
	app.RunLoop();
}
