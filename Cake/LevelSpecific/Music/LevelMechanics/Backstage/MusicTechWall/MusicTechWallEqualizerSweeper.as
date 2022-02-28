import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechWallEqualizerBarComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechActorBase;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechWallEqualizerNoiseComponent;
import Vino.Checkpoints.Volumes.DeathVolume;

class AMusicTechWallEqualizerSweeper : AMusicTechActorBase
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BarCenterPlacement;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent NoiseCenterPlacement;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedLeftEqualizerValue;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedRightEqualizerValue;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedLeftRotationValue;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedRightRotationValue;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedTopNoiseRotationValue;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedBottomNoiseRotationValue;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(Category = "Death Volumes")		
	ADeathVolume TopDeathVolume;
	
	UPROPERTY(Category = "Death Volumes")	
	ADeathVolume BotDeathVolume;

	UPROPERTY(BlueprintReadWrite)
	bool bAudioActive = true;

	UPROPERTY()
	UStaticMesh BarMesh;

	UPROPERTY()
	UMaterialInterface BarMat;

	UPROPERTY()
	UStaticMesh NoiseMesh;

	UPROPERTY()
	UMaterialInterface NoiseMat;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> NoiseDeathFX;


	TArray<UMusicTechWallEqualizerBarComponent> BarComponentArray;
	TArray<UMusicTechWallEqualizerNoiseComponent> TopNoiseComponentArray;
	TArray<UMusicTechWallEqualizerNoiseComponent> BottomNoiseComponentArray;

	UPROPERTY()
	int NumberOfBars = 10;

	UPROPERTY()
	int NumberOfNoiseBars = 50;

	UPROPERTY()
	float TotalWidth = 250.f;

	float CompXLocation = 0.f;
	float WidthAddition = 0.f;
	float BarEQPlacementAddition = 0.f;
	float BarEqPlacementDivider = 0.f;
	float CurrentLeftEQPlacement = 0.f;
	float CurrentRightEQPlacement = 0.f;
	float CurrentLeftRotationRate = 0.f;
	float TargetLeftRotationRate = 0.f;
	float WheelRotationRate = -14.f;
	float LeftRotationRate = 0.f;
	float RightRotationRate = 0.f;
	float RotationValue = 0.f;

	float CurrentTopNoisePlacement = 0.f;
	float CurrentBottomNoisePlacement = 0.f;
	float Time = 0.f;

	float TopAlpha = 0.f;
	float TopTimerDuration = 4.f;
	float TopTimer = 0.f;
	float BottomAlpha = 0.f;
	float BottomTimerDuration = 4.f;
	float BottomTimer = BottomTimerDuration / 2.f;

	float TargetLeftEqualizerValue = 0.0f;
	float TargetRightEqualizerValue = 0.0f;

	FVector2D LeftInput;
	FVector2D PreviousLeftInput;

	TSubclassOf<UMusicTechWallEqualizerBarComponent> Component;
	
	UMusicTechWallEqualizerNoiseComponent LastTopNoise;
	UMusicTechWallEqualizerNoiseComponent LastBottomNoise;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		WidthAddition = TotalWidth / (NumberOfBars - 1);
		float NumberOfBarsFloat = NumberOfBars;
		BarEqPlacementDivider = 1 / NumberOfBarsFloat;
		CompXLocation = -TotalWidth / 2;

		for (int i = 0; i < NumberOfBars; i++)
		{
			UMusicTechWallEqualizerBarComponent Comp = UMusicTechWallEqualizerBarComponent::Create(this, FName("EQComp" + i));
			BarComponentArray.Add(Comp);
			Comp.SetRelativeLocation(FVector(CompXLocation, BarCenterPlacement.RelativeLocation.Y, 0.f));
			Comp.SetRelativeRotation(FRotator(180.f, 0.f, 0.f));
			Comp.SetStaticMesh(BarMesh);
			Comp.SetMaterial(0, BarMat);
			Comp.BarEQPlacement = BarEQPlacementAddition;

			if (i + 1 > NumberOfBars / 2)
				Comp.bControlledWithLeftStick = false;
			else
				Comp.bControlledWithLeftStick = true;

			BarEQPlacementAddition += BarEqPlacementDivider;
			CompXLocation += WidthAddition;		
		}

		//WidthAddition = TotalWidth / (NumberOfNoiseBars - 1);
		float NumberOfNoiseBarsFloat = NumberOfNoiseBars;
		BarEqPlacementDivider = 1 / NumberOfNoiseBarsFloat;
		BarEQPlacementAddition = 0.f;
		CompXLocation = -3000.f;

		for (int i = 0; i < NumberOfNoiseBars; i++)
		{
			UMusicTechWallEqualizerNoiseComponent TopNoise = UMusicTechWallEqualizerNoiseComponent::Create(this, FName("TopNoiseComp" + i));
			TopNoiseComponentArray.Add(TopNoise);
			TopNoise.SetRelativeLocation(FVector(CompXLocation, NoiseCenterPlacement.RelativeLocation.Y, NoiseCenterPlacement.RelativeLocation.Z));
			TopNoise.SetRelativeRotation(FRotator(180.f, 0.f, 0.f));
			TopNoise.SetStaticMesh(NoiseMesh);
			TopNoise.SetMaterial(0, NoiseMat);
			TopNoise.TargetScaleZ = 18.f;
			TopNoise.BarEQPlacement = BarEQPlacementAddition;
			TopNoise.IsTop = true;
			TopNoise.Neighbour = LastTopNoise;
			TopNoise.NoiseDeathFX = NoiseDeathFX;
			LastTopNoise = TopNoise;

			UMusicTechWallEqualizerNoiseComponent BottomNoise = UMusicTechWallEqualizerNoiseComponent::Create(this, FName("BottomNoiseComp" + i));
			BottomNoiseComponentArray.Add(BottomNoise);
			BottomNoise.SetRelativeLocation(FVector(CompXLocation, BarCenterPlacement.RelativeLocation.Y, BarCenterPlacement.RelativeLocation.Z));
			BottomNoise.SetStaticMesh(NoiseMesh);
			BottomNoise.SetMaterial(0, NoiseMat);
			BottomNoise.TargetScaleZ = 18.f;
			BottomNoise.BarEQPlacement = BarEQPlacementAddition;
			BottomNoise.IsTop = false;
			BottomNoise.Neighbour = LastBottomNoise;
			BottomNoise.NoiseDeathFX = NoiseDeathFX;
			LastBottomNoise = BottomNoise;

			BarEQPlacementAddition += BarEqPlacementDivider;
			CompXLocation += WidthAddition;			
		}

		SetControlSide(Game::GetCody());
	}

	UFUNCTION()
	void RotationRateUpdate(float NewLeftRotationRate, float NewRightRotationRate)
	{
		Super::RotationRateUpdate(NewLeftRotationRate, NewRightRotationRate);
		LeftRotationRate = NewLeftRotationRate;
		RightRotationRate = NewRightRotationRate;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Time += DeltaTime / 1.f;

		for (UMusicTechWallEqualizerBarComponent Comp : BarComponentArray)
		{
			Comp.CurrentLeftEQPlacement = CurrentLeftEQPlacement;
			Comp.CurrentRightEQPlacement = CurrentRightEQPlacement;
			Comp.UpdateEqComp(DeltaTime);
		}

		for (auto Noise : TopNoiseComponentArray)
		{
			Noise.CurrentNoisePlacement = CurrentTopNoisePlacement;
			Noise.UpdateNoiseComp(DeltaTime);
		}

		for (auto Noise : BottomNoiseComponentArray)
		{
			Noise.CurrentNoisePlacement = CurrentBottomNoisePlacement;
			Noise.UpdateNoiseComp(DeltaTime);
		}

		if(HasControl())
		{
			TargetLeftEqualizerValue += LeftRotationRate * 5.0f;
			SyncedLeftEqualizerValue.Value += LeftRotationRate * 5.0f;
			SyncedLeftRotationValue.Value += LeftRotationRate;
			SyncedLeftRotationValue.Value = FMath::Clamp(SyncedLeftRotationValue.Value, 0.0f, 50.0f);

			TargetRightEqualizerValue += RightRotationRate * 5.0f;
			SyncedRightEqualizerValue.Value += RightRotationRate * 5.0f;
			SyncedRightRotationValue.Value += RightRotationRate;
			SyncedRightRotationValue.Value = FMath::Clamp(SyncedRightRotationValue.Value, 50.0f, 100.0f);

			TopTimer -= DeltaTime;
			TopAlpha -= DeltaTime;
			
			if (TopTimer <= 0.f)
			{
				TopTimer = TopTimerDuration;
				TopAlpha = TopTimerDuration/2.f;
			}

			BottomTimer -= DeltaTime;
			BottomAlpha -= DeltaTime;
			BottomAlpha = FMath::Max(0.f, BottomAlpha);
			if (BottomTimer <= 0.f)
			{
				BottomTimer = BottomTimerDuration;
				BottomAlpha = BottomTimerDuration/2.f;
			}

			SyncedTopNoiseRotationValue.Value = FMath::GetMappedRangeValueClamped(FVector2D(2.f, 0.f), FVector2D(1.f, 0.f), TopAlpha);
			SyncedBottomNoiseRotationValue.Value = FMath::GetMappedRangeValueClamped(FVector2D(2.f, 0.f), FVector2D(1.f, 0.f), BottomAlpha);
		}
		
		if(CurrentTopNoisePlacement == 0 && CurrentTopNoisePlacement < SyncedTopNoiseRotationValue.Value)
			SetCapabilityActionState(n"AudioStartTopNoise", EHazeActionState::ActiveForOneFrame);

		if(CurrentBottomNoisePlacement == 0 && CurrentBottomNoisePlacement < SyncedBottomNoiseRotationValue.Value)
			SetCapabilityActionState(n"AudioStartBotNoise", EHazeActionState::ActiveForOneFrame);
	
		if (SyncedLeftRotationValue.Value > 0)
			CurrentLeftEQPlacement = SyncedLeftRotationValue.Value / 100.f;
		else
			CurrentLeftEQPlacement = 0.f;

		if (SyncedRightRotationValue.Value > 0)
			CurrentRightEQPlacement = SyncedRightRotationValue.Value / 100.f;
		else
			CurrentRightEQPlacement = 0.f;

		CurrentTopNoisePlacement = SyncedTopNoiseRotationValue.Value;
		CurrentBottomNoisePlacement = SyncedBottomNoiseRotationValue.Value;
	}

	UFUNCTION()
	void SetSweeperActive(bool bActive)
	{		
		if (bActive)
			EnableActor(nullptr);
		else
			DisableActor(nullptr);
	}
}