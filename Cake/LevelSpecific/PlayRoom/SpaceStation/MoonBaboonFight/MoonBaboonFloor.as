import Peanuts.Audio.AudioStatics;
import Peanuts.Network.RelativeCrumbLocationCalculator;

UCLASS(Abstract)

event void FOnFloorLevelReached(EMoonBaboonFloorLevels FloorLevel);

class AMoonBaboonFloor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = DefaultComponent)
	UStaticMeshComponent FloorMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Gate1;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Gate2;

	UPROPERTY(DefaultComponent)
	UHazeInheritPlatformVelocityComponent InheritVelocityComp;
	default InheritVelocityComp.bInheritVerticalVelocity = true;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RaiseFloorAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RaiseFloorFinishedAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RaiseFloorTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike CloseGatesTimeLike;

	UPROPERTY()
	FOnFloorLevelReached OnFloorLevelReached;

	UPROPERTY()
	EMoonBaboonFloorLevels CurrentFloorLevel;
	EMoonBaboonFloorLevels DesiredLevel;

	FVector BottomLocation;
	FVector StartLocation;
	FVector TargetLocation;

	UPROPERTY()
	bool bPreviewClosedFloor = false;

	UPROPERTY()
	bool bPreviewLocation = false;

	UPROPERTY()
	float RaiseFloorDuration = 12.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BottomLocation = ActorLocation;

		RaiseFloorTimeLike.SetPlayRate(1/RaiseFloorDuration);
		RaiseFloorTimeLike.BindUpdate(this, n"UpdateRaiseFloor");
		RaiseFloorTimeLike.BindFinished(this, n"FinishRaiseFloor");

		CloseGatesTimeLike.SetPlayRate(0.75f);
		CloseGatesTimeLike.BindUpdate(this, n"UpdateCloseGates");
		CloseGatesTimeLike.BindFinished(this, n"FinishCloseGates");
	}

	UFUNCTION()
	void SetFloorLevel(EMoonBaboonFloorLevels NewLevel)
	{
		CurrentFloorLevel = NewLevel;
		SetActorLocation(GetFloorLevelLocation(CurrentFloorLevel));
	}

	FVector GetFloorLevelLocation(EMoonBaboonFloorLevels TargetLevel)
	{
		FVector FloorLevelLocation;

		switch (TargetLevel)
		{
			case EMoonBaboonFloorLevels::Bottom:
				FloorLevelLocation = BottomLocation;
			break;
			case EMoonBaboonFloorLevels::FirstFloor:
				FloorLevelLocation = BottomLocation + FVector(0.f, 0.f, 5000.f);
			break;
			case EMoonBaboonFloorLevels::SecondFloor:
				FloorLevelLocation = BottomLocation + FVector(0.f, 0.f, 10030.f);
			break;
			case EMoonBaboonFloorLevels::TopFloor:
				FloorLevelLocation = BottomLocation + FVector(0.f, 0.f, 20000.f);
			break;
		}

		return FloorLevelLocation;
	}

	UFUNCTION()
	void ChangeRaiseFloorDuration(float Duration)
	{
		RaiseFloorDuration = Duration;
		RaiseFloorTimeLike.SetPlayRate(1/RaiseFloorDuration);
	}

	UFUNCTION()
	void RaiseFloor(EMoonBaboonFloorLevels TargetLevel)
	{
		if (CurrentFloorLevel == EMoonBaboonFloorLevels::TopFloor)
			return;

		DesiredLevel = TargetLevel;
		StartLocation = ActorLocation;
		TargetLocation = GetFloorLevelLocation(DesiredLevel);
		RaiseFloorTimeLike.PlayFromStart();
		HazeAkComp.HazePostEvent(RaiseFloorAudioEvent);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (Player.IsCody() && TargetLevel == EMoonBaboonFloorLevels::TopFloor)
			{

			}
			else
			{
				UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
				CrumbComp.MakeCrumbsUseCustomWorldCalculator(URelativeCrumbLocationCalculator::StaticClass(), this, FloorMesh);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRaiseFloor(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(StartLocation, TargetLocation, CurValue);
		SetActorLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRaiseFloor()
	{
		CurrentFloorLevel = DesiredLevel;
		OnFloorLevelReached.Broadcast(CurrentFloorLevel);
		HazeAkComp.HazePostEvent(RaiseFloorFinishedAudioEvent);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
			CrumbComp.RemoveCustomWorldCalculator(this);
		}
	}

	UFUNCTION(DevFunction)
	void CloseGates(bool bSnapShut)
	{
		if (bSnapShut)
		{
			Gate1.SetRelativeLocation(FVector::ZeroVector);
			Gate2.SetRelativeLocation(FVector::ZeroVector);
		}
		else
		{
			CloseGatesTimeLike.PlayFromStart();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateCloseGates(float CurValue)
	{
		FVector Gate1Loc = FMath::Lerp(FVector(0.f, -2500.f, 0.f), FVector::ZeroVector, CurValue);
		FVector Gate2Loc = FMath::Lerp(FVector(0.f, 2500.f, 0.f), FVector::ZeroVector, CurValue);

		Gate1.SetRelativeLocation(Gate1Loc);
		Gate2.SetRelativeLocation(Gate2Loc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishCloseGates()
	{

	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewClosedFloor)
		{
			Gate1.SetRelativeLocation(FVector::ZeroVector);
			Gate2.SetRelativeLocation(FVector::ZeroVector);
		}
		else
		{
			Gate1.SetRelativeLocation(FVector(0.f, -2500.f, 0.f));
			Gate2.SetRelativeLocation(FVector(0.f, 2500.f, 0.f));
		}

		if (bPreviewLocation)
		{
			float Height;
			switch (CurrentFloorLevel)
			{
				case EMoonBaboonFloorLevels::Bottom:
					Height = 0.f;
				break;
				case EMoonBaboonFloorLevels::FirstFloor:
					Height = 5000.f;
				break;
				case EMoonBaboonFloorLevels::SecondFloor:
					Height = 10030.f;
				break;
				case EMoonBaboonFloorLevels::TopFloor:
					Height = 20000.f;
				break;
			}
			FloorMesh.SetRelativeLocation(FVector(0.f, 0.f, Height));
		}
		else
		{
			FloorMesh.SetRelativeLocation(FVector::ZeroVector);
		}

		if (bPreviewClosedFloor)
		{
			Gate1.SetRelativeLocation(FVector(0.f, 0.f, FloorMesh.RelativeLocation.Z));
			Gate2.SetRelativeLocation(FVector(0.f, 0.f, FloorMesh.RelativeLocation.Z));
		}
		else
		{
			Gate1.SetRelativeLocation(FVector(0.f, -2500.f, FloorMesh.RelativeLocation.Z));
			Gate2.SetRelativeLocation(FVector(0.f, 2500.f, FloorMesh.RelativeLocation.Z));
		}
	}
}

enum EMoonBaboonFloorLevels
{
	Bottom,
	FirstFloor,
	SecondFloor,
	TopFloor
}