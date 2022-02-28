import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.IceAxeActor;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingAxeManager;
import Vino.Tutorial.TutorialStatics;
import Vino.Tutorial.TutorialPrompt;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingTarget;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeIceTapThrow;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingStatics;

enum EPlayerAxeState
{
	Default,
	PickingUpAxe,
	AxeReady,
	Throwing
};

enum EAxePlayerGameState
{
	Inactive,
	WinnerAnnouncement,
	BeforePlay,
	InPlay
};

event void FPlayerCancelAxeThrowing(UInteractionComponent InteractComp, AHazePlayerCharacter Player);

class UAxeThrowingPlayerComp : UActorComponent
{
	UPROPERTY(Category = "Setup")
	UHazeCameraSpringArmSettingsDataAsset DefaultSpringArmSettings;

	UPROPERTY(Category = "Setup")
	ULocomotionFeatureSnowGlobeIceTapThrow IcicleFeatureMay;  

	UPROPERTY(Category = "Setup")
	ULocomotionFeatureSnowGlobeIceTapThrow IcicleFeatureCody;  

	UPROPERTY(Category = "Setup")
	UForceFeedbackEffect ThrowFeedback;

	EPlayerAxeState PlayerAxeState;

	EAxePlayerGameState AxePlayerGameState;

	FVector HeldLoc;
	FVector EndLocation;
	
	FPlayerCancelAxeThrowing OnPlayerCancelAxeThrowingEvent;

	UInteractionComponent OurInteractionComp;

	UPROPERTY(Category = "Setup")
	TSubclassOf<AIceAxeActor> IceAxeActorClass;

	TArray<AAxeThrowingAxeManager> AxeManagerArray;

	AAxeThrowingStartInteraction StartInteraction;

	AAxeThrowingAxeManager AxeManager;

	AAxeThrowingTarget CurrentTarget;
	AHazeActor IcicleProp;

	AIceAxeActor ChosenAxe;

	FVector Forward;

	UPROPERTY()
	float BSPlayerTurn;
	
	float NextPickupTime;

	bool bShowingTutorial;
	bool bGameFinished;
	bool bCanCancel;
	bool bCanShoot;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UHazeUserWidget> AimWidget;
	UHazeUserWidget WidgetInUse;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt RightShootTrigger;
	default RightShootTrigger.Action = ActionNames::PrimaryLevelAbility;
	default RightShootTrigger.MaximumDuration = -1.f;

	FVector ReturnLoc;
	FRotator ReturnRot;

	FIceAxeSettings IceAxeSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(AxeManagerArray);

		if (AxeManagerArray.Num() > 0)
			AxeManager = AxeManagerArray[0];

		bCanCancel = true;

		SetCanShoot(true);
	}

	UFUNCTION()
	void ReturnAxeToOrigin()
	{
		if (ChosenAxe != nullptr)
		{
			ChosenAxe.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			if (ChosenAxe.bIsActive)
				ChosenAxe.DeactivateAxe();
		}

		if (IcicleProp != nullptr && IcicleProp.IsActorDisabled(Owner))
			IcicleProp.EnableActor(Owner);
	}

	UFUNCTION()
	void ThrowIcicleFeedback(AHazePlayerCharacter Player)
	{
		Player.PlayForceFeedback(ThrowFeedback, false, false, NAME_None);
	}

	UFUNCTION()
	void ShowRightTrigger(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, RightShootTrigger, this);
	}

	UFUNCTION()
	void RemoveRightTrigger(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION()
	void ShowCancel(AHazePlayerCharacter Player)
	{
		ShowCancelPrompt(Player, this);
	}

	UFUNCTION()
	void RemoveCancelPrompt(AHazePlayerCharacter Player)
	{
		RemoveCancelPromptByInstigator(Player, this);
	}

	UFUNCTION()
	void SetGameFinished(bool bInGameFinished)
	{
		bGameFinished = bInGameFinished;
	}

	UFUNCTION()
	void SetCanShoot(bool bInCanShoot)
	{
		bCanShoot = bInCanShoot;
	}

	UFUNCTION()
	void ShowAimer(AHazePlayerCharacter Player)
	{
		UCameraUserComponent UserComp = UCameraUserComponent::Get(Player); 
		
		UserComp.SetAiming(this);
		WidgetInUse = Cast<UHazeUserWidget>(Player.AddWidget(AimWidget));
	}

	UFUNCTION()
	void RemoveAimer(AHazePlayerCharacter Player)
	{
		UCameraUserComponent UserComp = UCameraUserComponent::Get(Player); 
		
		Player.RemoveWidget(WidgetInUse);
		UserComp.ClearAiming(this);
	}
}