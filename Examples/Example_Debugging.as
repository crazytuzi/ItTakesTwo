/*
    This is a generic example debug capability showing what you can make in the debug system
	The debug capability is not included in the final verision of the game.
	All this is visible in the debug tab.
	You can change the visual settings of the debugging to show more or less under the debug tab.
	Debug input can be turned on or off by using F9.
*/


/*
	It is more optimized to encapsule the debug code in the "TEST" define
	This will make sure the code inside is excluded from the final version of the game
*/
#if TEST
	const bool ThisVaribaleWillNotBeIncludedInTheFinalVersionOfTheGame = true;
#endif

class UExampleDebugCapability : UHazeDebugCapability
{
	// This function lets you setup all the debug information you want to use.
	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		// The debug values can be also be added as console variables
		const bool bMakeIntoConsoleVariable = false;
		
		// This is a true or false statement.
		DebugValues.AddDebugSettingsFlag(n"TestFlag", "For Testing", bMakeIntoConsoleVariable);

		// This is a slider value. Good if you want to have multiple settings of the same variable
		DebugValues.AddDebugSettingsValue(n"TestValue", 10, "For Testing", bMakeIntoConsoleVariable);


		// A function call is connected to a button and will call a function in the debug capability.
		// The function name must have a valid UFUNCTION with the same name in the capability.
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"TriggerDebugFunction", "Test Function");
		

		// A passive button is valid when the debug category button (Left Shoulder, or Right Ctrl) is not held,
		// and you are not locked into a debug category
		Handler.AddPassiveUserButton(EHazeDebugPassiveUserCategoryButtonType::DPadDown);
		
		// A active button is valid when the debug category button (Left Shoulder, or Right Ctrl) is held,
		// and the current selected debug category is equal to the provided category
		// When adding a active user button, that will also add the category to the debug menu
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"TestCategory");

		// This buttons is always valid
		Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::F1);


		// You can make a debug capability into a locked category capability.
		//As long as this capability is active, the exclusive category will be locked.
		DebugValues.UseExlusiveLockedCategory(n"ExampleLockedCategory");

		// When you have locked the category, all these button types becomes available
		Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::MouseButtonRight);
	}

	// This is the function connected to the 'AddFunctionCall' function
	UFUNCTION()
	void TriggerDebugFunction()
	{
		PrintToScreen("Test Function Triggered", 4);
	}
}


class AExampleDebugActorType : AHazeActor
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Debug capabilities is added with the 'AddDebugCapability' function
		// You can also add the to the sheets.
		AddDebugCapability(n"ExampleDebugCapability");

		// This is how you read the debug value
		int Value = 0;
		if(GetDebugValue(n"TestValue", Value))
		{
			PrintToScreen("TestValue is set to " + Value, 4);
		}

		// This is how you read the debug flag
		if(GetDebugFlag(n"TestFlag"))
		{
			PrintToScreen("TestFlag is set", 4);
		}
	}
};