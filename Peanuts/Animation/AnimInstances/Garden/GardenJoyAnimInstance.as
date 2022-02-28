import Cake.LevelSpecific.Garden.Greenhouse.Joy;

class UGardenJoyAnimInstance : UHazeAnimInstanceBase
{
	// Animations
	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData MhInfectedArm;

	UPROPERTY(Category = "Phase 3")
    FHazePlaySequenceData CodyTakesControl;

	UPROPERTY(Category = "Phase 1")
    FHazePlayBlendSpaceData Phase1ButtonMash;

	UPROPERTY(Category = "Phase 2")
    FHazePlayBlendSpaceData Phase2ButtonMash;

	UPROPERTY(Category = "Phase 3")
    FHazePlayBlendSpaceData Phase3ButtonMash;

	UPROPERTY(Category = "Phase 3")
    FHazePlaySequenceData SummonSide;

	UPROPERTY(Category = "Phase 3")
    FHazePlaySequenceData SummonCenter;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float ButtonMashProgress = 0.f;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bArmInfected;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bButtonMashActive;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	int Phase = 1;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bCodyTakesCtrl;

	//UPROPERTY()
	//bool bAllowButtonMashExit;

	UPROPERTY()
	bool bSummonSide;

	UPROPERTY()
	bool bSummonCenter;

	int IntButtonMash;
	int ExpectedButtonMashValue;
	AJoy JoyActor;


	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		bArmInfected = false;
		JoyActor = Cast<AJoy>(OwningActor);
	}


	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(JoyActor == nullptr)
			return;

		bButtonMashActive = JoyActor.bButtonMashActive;
		ButtonMashProgress = JoyActor.fInterpFloat;
		//bAllowButtonMashExit = JoyActor.bAllowButtonMashExit;
		Phase = JoyActor.Phase;
		bArmInfected = false;//(Phase == 1);
		bCodyTakesCtrl = GetAnimBoolParam(n"CodyTakesControl", true);

		if(Phase == 1)
			ExpectedButtonMashValue = 1;
		else if (Phase == 2)
			ExpectedButtonMashValue = 3;
		else if (Phase == 3)
			ExpectedButtonMashValue = 5;

		// Button mashing
		if(JoyActor.IntButtonMash == ExpectedButtonMashValue)
		{
			ButtonMashProgress = JoyActor.fInterpFloat;
		}

		if(GetAnimBoolParam(n"SummonCenter", true))
		{
			bSummonCenter = true;
		}
		else if(GetAnimBoolParam(n"SummonLeftRight", true))
		{
			bSummonSide = true;
		}
	}

}