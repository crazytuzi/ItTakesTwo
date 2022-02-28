class UControlsDebugMenu : UHazeDebugValuesDebugMenu
{

}

class UDebugSubCategoryWidget : UHazeDebugValuesPerPlayerSubCategoryWidget
{

}

class UDebugSubCategoryInnerWidget : UHazeUserWidget
{
	UFUNCTION(BlueprintPure)
	ESlateVisibility GetVisibilityType(FHazeDebugPerPlayerSubWidgetRebuildGuiData RebuildData)const
	{
		if(RebuildData.CurrentDebugDisplayLevel == 0)
		{
			return ESlateVisibility::Collapsed;
		}
		else if(RebuildData.CurrentDebugDisplayLevel == 1)
		{
			if(RebuildData.bCurrentCategoryIsLocked)
			{
				return ESlateVisibility::Collapsed;
			}
		}

		return ESlateVisibility::Visible;
	}

	UFUNCTION(BlueprintPure)
	FString GetCategoryName(FName CurrentName)const
	{
		if(CurrentName == PerActorDebugValueCreationInformation::GetDefaultActiveUserCategoryName())
			return FName(n"Default").ToString();
		else
			return CurrentName.ToString();
	}
}


struct FHazeDebugButtonSetupData
{
	UPROPERTY()
	FString ButtonText;

	UPROPERTY()
	FName Category;

	UPROPERTY()
	bool bShowCategory = true;
}

class UHazeDebugButton : UHazePerActorDebugButtonWidget
{
	UPROPERTY()
	bool bSubCategoryButton = false;

	FString ConvertButtonType(FKey Button) const
	{
		FName KeyName = Button.GetKeyName();

		if(KeyName == n"Gamepad_LeftShoulder")
			return "[LB]";
		else if(KeyName == n"Gamepad_RightShoulder")
			return "[RB]";
		if(KeyName == n"Gamepad_LeftTrigger")
			return "[LT]";
		else if(KeyName == n"Gamepad_RightTrigger")
			return "[RT]";

		else if(KeyName == n"Gamepad_RightThumbstick")
			return "[RightThumbstick]";

		else if(KeyName == n"Gamepad_DPad_Up")
			return "<DPad_Up>";
		else if(KeyName == n"Gamepad_DPad_Down")
			return "<DPad_Down>";
		else if(KeyName == n"Gamepad_DPad_Left")
			return "<DPad_Left>";
		else if(KeyName == n"Gamepad_DPad_Right")
			return "<DPad_Right>";

		else if(KeyName == n"Up")
			return "(Arrow_Up)";
		else if(KeyName == n"Down")
			return "(Arrow_Down)";
		else if(KeyName == n"Left")
			return "(Arrow_Left)";
		else if(KeyName == n"Right")
			return "(Arrow_Right)";

		else if(KeyName == n"Gamepad_FaceButton_Top")
			return "<Face_Top>";
		else if(KeyName == n"Gamepad_FaceButton_Bottom")
			return "<Face_Bot>";
		else if(KeyName == n"Gamepad_FaceButton_Left")
			return "<Face_Left>";
		else if(KeyName == n"Gamepad_FaceButton_Right")
			return "<Face_Right>";
		
		else if(KeyName == n"LeftMouseButton")
			return "(Mouse_Left)";
		else if(KeyName == n"RightMouseButton")
			return "(Mouse_Right)";
		else if(KeyName == n"MouseWheelAxis")
			return "(MouseWheelAxis)";

		else if(KeyName == n"Add")
			return "(+)";
		else if(KeyName == n"Subtract")
			return "(-)";
		else if(KeyName == n"P")
			return "(P)";
		else if(KeyName == n"K")
			return "(K)";
		else if(KeyName == n"Y")
			return "(Y)";
		else if(KeyName == n"T")
			return "(T)";
		else if(KeyName == n"C")
			return "(C)";
		else if(KeyName == n"V")
			return "(V)";
		else if(KeyName == n"G")
			return "(G)";

		else if(KeyName == n"F1")
			return "(F1)";
		else if(KeyName == n"F2")
			return "(F2)";
		else if(KeyName == n"F3")
			return "(F3)";
		else if(KeyName == n"F4")
			return "(F4)";
		else if(KeyName == n"F5")
			return "(F5)";
		else if(KeyName == n"F6")
			return "(F6)";
		else if(KeyName == n"F7")
			return "(F7)";
		else if(KeyName == n"F8")
			return "(F8)";
		else if(KeyName == n"F9")
			return "(F9)";
		else if(KeyName == n"F10")
			return "(F10)";

		return "Invalid";
	}

	UFUNCTION(BlueprintPure)
	TArray<FHazeDebugButtonSetupData> GetButtonDisplayText()const
	{
		TArray<FHazeDebugButtonSetupData> OutData;
	
		for(int i = 0; i < StoredEntry.Buttons.Num(); ++i)
		{
			FHazeDebugButtonSetupData OutText;
			const FHazePerActorDebugGuiButtonDataEntry& Input = StoredEntry.Buttons[i];
			
			if(Input.CategoryType == EHazeDebugPerActorDefaultCategories::ActiveUserNotLockedAlwaysValid)
			{
				if(Input.Type != StoredEntry.ActivationKey && Input.Type != StoredEntry.AlternativeActivationKey)
				{
					OutText.ButtonText += "Hold ";
					if(Input.Type.IsGamepadKey())
						OutText.ButtonText += ConvertButtonType(StoredEntry.ActivationKey);		
					else
						OutText.ButtonText += ConvertButtonType(StoredEntry.AlternativeActivationKey);	
					OutText.ButtonText += " + ";	
				}
			}

			if(Input.ActivationType == EPerActorDebugInputActivationType::Hold)
			{
				OutText.ButtonText += "(Hold) ";		
			}
			else if(Input.ActivationType == EPerActorDebugInputActivationType::DoubleTap)
			{
				OutText.ButtonText += "(Double Tap) ";
			}
				
			OutText.ButtonText += ConvertButtonType(Input.Type);
			OutText.Category = Input.Category;
			if(bSubCategoryButton)
			{
				OutText.bShowCategory = false;
			}
			else if(OutText.Category == NAME_None)
			{
				OutText.bShowCategory = false;
			}
			else if(OutText.Category == n"DefaultPassiveDebug")
			{
				OutText.Category = n"Passive Mode";
			}
			else if(OutText.Category == n"DefaultActiveDebug")
			{
				OutText.Category = n"Default Category";
			}
				
			OutData.Add(OutText);
		}
	
		return OutData;
	}



	UFUNCTION(BlueprintPure)
	bool ShowDescription()const
	{
		return true;
	}
}