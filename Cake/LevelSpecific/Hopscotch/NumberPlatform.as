import Cake.LevelSpecific.Hopscotch.NumberCube;
import Cake.LevelSpecific.Hopscotch.FlippingPlatform;
import Cake.LevelSpecific.Hopscotch.CrushingNumberCubes;
import Cake.LevelSpecific.Hopscotch.CardboardNumberCube;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void NumberPlatformPlayerIn();
event void NumberPlatformPlayerOut();

class ANumberPlatform : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

    UPROPERTY(DefaultComponent, Attach = MeshRoot)
    UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBounceComponent BounceComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent NumberPlatformInAudioEvent;

    UPROPERTY()
    EHopScotchNumber HopscotchNumber;

	UPROPERTY()
    TArray<UMaterialInstance> AnimalMaterialArray;

	UPROPERTY()
    TArray<UMaterialInstance> NumberMaterialArray;

	UPROPERTY()
	bool bNumbers = false;

	UPROPERTY()
	bool bShouldApplyPOI;

	UPROPERTY()
	bool bShouldOnlyApplyPoiOnce = false;

	UPROPERTY()
	bool bCamOffsetOnPOI = false;

	UPROPERTY(Meta = (EditCondition="bCamOffsetOnPOI", EditConditionHides))
	FVector CamOffsetOnPOI = FVector::ZeroVector;

	UPROPERTY(ExposeOnSpawn, meta = (MakeEditWidget), meta = (EditCondition = "bCamOffsetOnPOI"))
	FVector ClearOffsetPOILocation;

	bool bHasAppliedPoi;

	UPROPERTY(ExposeOnSpawn, meta = (MakeEditWidget), meta = (EditCondition = "bShouldApplyPOI"))
	FVector POILocation;

    UPROPERTY()
    TArray<ANumberCube> NumberCubesToActivate;

    UPROPERTY()
    TArray<AFlippingPlatform> FlippingPlatformsToActivate;

    UPROPERTY()
    TArray<ACrushingNumberCubes> CrushingCubesToActivate;

	UPROPERTY()
	TArray<ACardboardNumberCube> CardboardNumberCubeToActivate;

	UPROPERTY()
	UForceFeedbackEffect StepFeedback;

    int AmountOfPlayersOnButton;

    bool bCanBeToggled = true;

    bool bIsActive;

	UPROPERTY()
	bool bDebugMode = false;

	FHazePointOfInterest PointOfInterest;

	FVector POILocationWorld;

	AHazePlayerCharacter PlayerGotPOI;

   UPROPERTY()
   NumberPlatformPlayerIn AudioNumberCubeOnIn;

   UPROPERTY()
   NumberPlatformPlayerOut AudioNumberCubeOnOut;

   UPROPERTY()
   float TimeBetweenActivations = 0.05f;

   int CurrentIndex = 0;
   bool bShouldIncreaseIndex = false;
   float IncreaseIndexTimer = 0.f;
   bool bHasActivatedNumberCubes = false;

	default PrimaryActorTick.bStartWithTickEnabled = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerLandedOnActor");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"PlayerLeftActor");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		POILocationWorld = GetActorTransform().TransformPosition(POILocation);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldIncreaseIndex)
		{
			IncreaseIndexTimer -= DeltaTime;
			if (IncreaseIndexTimer <= 0.f && CurrentIndex < NumberCubesToActivate.Num())
			{
				if (NumberCubesToActivate[CurrentIndex].bShouldBeHidden || NumberCubesToActivate[CurrentIndex].bVisibleWhileDeactivated && HopscotchNumber == NumberCubesToActivate[CurrentIndex].HopScotchNumber)
					NumberCubesToActivate[CurrentIndex].NetActivatePlatform();
				
				CurrentIndex++;
				IncreaseIndexTimer = TimeBetweenActivations;
			}

			if (CurrentIndex >= NumberCubesToActivate.Num())
				SetActorTickEnabled(false);
		}
		else if (!bShouldIncreaseIndex)
		{
			IncreaseIndexTimer -= DeltaTime;
			if (IncreaseIndexTimer <= 0.f && CurrentIndex > 0)
			{
				CurrentIndex--;
				IncreaseIndexTimer = TimeBetweenActivations;

				if (NumberCubesToActivate[CurrentIndex].bShouldBeHidden || NumberCubesToActivate[CurrentIndex].bVisibleWhileDeactivated && HopscotchNumber == NumberCubesToActivate[CurrentIndex].HopScotchNumber)
					NumberCubesToActivate[CurrentIndex].NetDeactivatePlatform();	
			}

			if (CurrentIndex == 0)
				SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void PlayerLandedOnActor(AHazePlayerCharacter Player, const FHitResult& Hit)
	{		
		AmountOfPlayersOnButton++;

		if (AmountOfPlayersOnButton == 1)
		{
			AudioNumberCubeOnIn.Broadcast();
			UHazeAkComponent::HazePostEventFireForget(NumberPlatformInAudioEvent, this.GetActorTransform());

			Player.PlayForceFeedback(StepFeedback, false, false, n"NumberPlatform");
			
			if (HasControl())
			{
				bShouldIncreaseIndex = true;
				SetActorTickEnabled(true);

				for (AFlippingPlatform FlippingPlatform : FlippingPlatformsToActivate)
				{                    
					if (HopscotchNumber == FlippingPlatform.HopscotchNumber)
						FlippingPlatform.NetFlipPlatform();
				}
				for (ACrushingNumberCubes CrushingCube : CrushingCubesToActivate)
				{                    
					if (HopscotchNumber == CrushingCube.HopscotchNumber)
						CrushingCube.NetLiftCube();
				}

				for (ACardboardNumberCube CardboardCube : CardboardNumberCubeToActivate)
				{
					if (HopscotchNumber == CardboardCube.HopscotchNumber)
						CardboardCube.NetActivateCube();
				}
			}
		}

		if (bShouldApplyPOI)
			SetCameraPointOfInterest(Player);
	}

	UFUNCTION()
	void PlayerLeftActor(AHazePlayerCharacter Player)
	{
		AmountOfPlayersOnButton--;

		if (AmountOfPlayersOnButton == 0)
		{
			AudioNumberCubeOnOut.Broadcast();
			if (HasControl())
			{
				bShouldIncreaseIndex = false;
				SetActorTickEnabled(true);

				for (AFlippingPlatform FlippingPlatform : FlippingPlatformsToActivate)
				{                    
					if (HopscotchNumber == FlippingPlatform.HopscotchNumber)
						FlippingPlatform.NetUnFlipPlatform();
				}
				for (ACrushingNumberCubes CrushingCube : CrushingCubesToActivate)
				{                    
					if (HopscotchNumber == CrushingCube.HopscotchNumber)
						CrushingCube.NetCrushCube();
				}

				for (ACardboardNumberCube CardboardCube : CardboardNumberCubeToActivate)
				{
					if (HopscotchNumber == CardboardCube.HopscotchNumber)
						CardboardCube.NetDeactivateCube();
				}
			}
		}
		ClearPOI();
	}

	void SetCameraPointOfInterest(AHazePlayerCharacter Player)
	{
		if (PlayerGotPOI != nullptr)
			return;
		
		if (bShouldOnlyApplyPoiOnce && bHasAppliedPoi)
			return;

		bHasAppliedPoi = true;
		
		PlayerGotPOI = Player;
		PointOfInterest.FocusTarget.WorldOffset = POILocationWorld; 
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PointOfInterest.Blend.BlendTime = 3.f;
		PlayerGotPOI.ApplyPointOfInterest(PointOfInterest, this);
		
		if (bCamOffsetOnPOI)
		{
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 3.f;
			PlayerGotPOI.ApplyPivotOffset(CamOffsetOnPOI, Blend, this);
		}

		System::SetTimer(this, n"ClearPOI", 3.f, false);
	}

	UFUNCTION()
	void ClearPOI()
	{
		if (PlayerGotPOI != nullptr)
		{
			PlayerGotPOI.ClearPointOfInterestByInstigator(this);

			if (bCamOffsetOnPOI)
			{
				PlayerGotPOI.ClearPivotOffsetByInstigator(this);

				PointOfInterest.bClearOnInput = true;
				PointOfInterest.FocusTarget.WorldOffset = GetActorTransform().TransformPosition(ClearOffsetPOILocation);
				PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
				PointOfInterest.Blend.BlendTime = 3.f;
				PointOfInterest.Duration = 3.f;
				PlayerGotPOI.ApplyPointOfInterest(PointOfInterest, this);
			}
			
			PlayerGotPOI = nullptr;
		}
	}
}