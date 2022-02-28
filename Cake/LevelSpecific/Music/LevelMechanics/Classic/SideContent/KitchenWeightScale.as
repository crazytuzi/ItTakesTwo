import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;


event void FOnPlayerLandedOnScale(AHazePlayerCharacter Player);

class AKitchenWeightScale : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 15000.f;

	UPROPERTY()
	FOnPlayerLandedOnScale OnPlayerLandedOnScale;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent UpAudioEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DownAudioEvent;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactComponent;
	//default ImpactComponent.bCanBeActivedLocallyOnTheRemote = false;

	UPROPERTY()
	ATextRenderActor TextRenderer;
	UPROPERTY()
	APlayerTrigger PlayerTrigger;

	UPROPERTY()
	float CodyWeightStaticWeight = 152.31;
	UPROPERTY()
	float MayWeightStaticWeight = 118.57;

	float CodysCurrentWeight;
	float MaysCurrentWeight;
	float DisplayNumber;
	float OffsetValue;

	bool bMayOnScale;
	bool bCodyOnScale;
	float TargetOffsetValue;
	float CurrentOffsetValue;

	FHazeAcceleratedFloat MeshOffestAcceleratedFloat;
	FHazeAcceleratedFloat ExtraMeshOffestAcceleratedFloat;

	FHazeAcceleratedFloat CurrentWeightAcceleratedFloat;
	FHazeAcceleratedFloat ExtraWeightAcceleratedFloat;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"LandedOnScale");
        BindOnDownImpactedByPlayer(this, OnPlayerLanded);
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnterScale");
		PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"PlayerLeaveScale");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ExtraWeightAcceleratedFloat.SpringTo(0, 15, 0.85, DeltaSeconds);
		CurrentWeightAcceleratedFloat.SpringTo(CodysCurrentWeight + MaysCurrentWeight + ExtraWeightAcceleratedFloat.Value, 15, 0.85, DeltaSeconds);

		
		if(bCodyOnScale == false && bMayOnScale == false)
		{
			TargetOffsetValue = 0;
			MeshOffestAcceleratedFloat.SpringTo(TargetOffsetValue, 70, 0.5, DeltaSeconds);
		}
		else if(bCodyOnScale == true && bMayOnScale == true)
		{
			TargetOffsetValue = -21;
			MeshOffestAcceleratedFloat.SpringTo(TargetOffsetValue, 150, 0.9, DeltaSeconds);
		}
		else if(bCodyOnScale == true)
		{
			TargetOffsetValue = -13;
			MeshOffestAcceleratedFloat.SpringTo(TargetOffsetValue, 70, 0.3, DeltaSeconds);
		}
		else if(bMayOnScale == true)
		{
			TargetOffsetValue = -8;
			MeshOffestAcceleratedFloat.SpringTo(TargetOffsetValue, 70, 0.3, DeltaSeconds);
		}

		ExtraMeshOffestAcceleratedFloat.SpringTo(0, 15, 0.85, DeltaSeconds);
		CurrentOffsetValue = MeshOffestAcceleratedFloat.Value + ExtraMeshOffestAcceleratedFloat.Value;
	//	CurrentOffsetValue = FMath::Lerp(CurrentOffsetValue, (MeshOffestAcceleratedFloat.Value + ExtraMeshOffestAcceleratedFloat.Value), DeltaSeconds);
	//	CurrentOffsetValue = FMath::Clamp(CurrentOffsetValue, -21, 25);
		Mesh.SetRelativeLocation(FVector(0,0, CurrentOffsetValue));

	//	PrintToScreen("MeshOffestAcceleratedFloat " + MeshOffestAcceleratedFloat.Value);
	//	PrintToScreen("ExtraMeshOffestAcceleratedFloat " + ExtraMeshOffestAcceleratedFloat.Value);
	//	PrintToScreen("CurrentOffsetValue " + CurrentOffsetValue);

		DisplayNumber = CurrentWeightAcceleratedFloat.Value;
		if(DisplayNumber < 0.1)
			DisplayNumber = 0;
		FText WeightText = Text::Conv_FloatToText(DisplayNumber, ERoundingMode::FromZero, false, true, 3, 4,2,2);
		TextRenderer.TextRender.SetText(WeightText);
	}

	UFUNCTION(NotBlueprintCallable)
    void LandedOnScale(AHazePlayerCharacter Player, FHitResult HitResult)
    {
		if(Player == Game::GetMay())
		{
			OnPlayerLandedOnScale.Broadcast(Game::GetMay());
			if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
			{
				ExtraWeightAcceleratedFloat.Value = ExtraWeightAcceleratedFloat.Value + 175;
				if(MeshOffestAcceleratedFloat.Value < - 7)
				{
					ExtraMeshOffestAcceleratedFloat.Value = -3;
				}
				else
				{
					ExtraMeshOffestAcceleratedFloat.Value = -10;
				}
			}	
		}
		if(Player == Game::GetCody())
		{
			OnPlayerLandedOnScale.Broadcast(Game::GetCody());
			if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
			{
				ExtraWeightAcceleratedFloat.Value = ExtraWeightAcceleratedFloat.Value + 190;
				if(MeshOffestAcceleratedFloat.Value < - 7)
				{
					ExtraMeshOffestAcceleratedFloat.Value = -3;
				}
				else
				{
					ExtraMeshOffestAcceleratedFloat.Value = -10;
				}
			}
		}
    }

	UFUNCTION()
	void PlayerEnterScale(AHazePlayerCharacter Player)
	{
		if(Player == Game::GetCody())
		{
			OnPlayerLandedOnScale.Broadcast(Game::GetCody());
			CodysCurrentWeight = CodyWeightStaticWeight;
			bCodyOnScale = true;
		}
		if(Player == Game::GetMay())
		{
			OnPlayerLandedOnScale.Broadcast(Game::GetMay());
			MaysCurrentWeight = MayWeightStaticWeight;
			bMayOnScale = true;
		}
		UHazeAkComponent::HazePostEventFireForget(DownAudioEvent, GetActorTransform());
	}
	UFUNCTION()
	void PlayerLeaveScale(AHazePlayerCharacter Player)
	{
		if(Player == Game::GetCody())
		{
			CodysCurrentWeight = 0;
			bCodyOnScale = false;
		}
		if(Player == Game::GetMay())
		{
			MaysCurrentWeight = 0;
			bMayOnScale = false;
		}
		UHazeAkComponent::HazePostEventFireForget(UpAudioEvent, GetActorTransform());
	}
}

