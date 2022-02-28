import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoSettings;

import bool IsTomatoDashTargetValid(AHazeActor) from "Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoDashTargetComponent";
import float GetHitRadius(AHazeActor) from "Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoDashTargetComponent";

class UTomatoTargetComponent : UActorComponent
{
	private TArray<AHazeActor> AvailableTargets;
	private TArray<AHazeActor> TargetsToRemove;
	private UTomatoSettings _TomatoSettings;

	AHazePlayerCharacter Player;

	bool HasAnyTargets() const
	{
		return AvailableTargets.Num() > 0;
	}

	void SetTomatoSettings(UTomatoSettings InTomatoSettings) property
	{
		_TomatoSettings = InTomatoSettings;
	}

	int GetNumTargets() const property { return AvailableTargets.Num(); }
	AHazeActor GetTarget(int Index)
	{
		return AvailableTargets[Index];
	}
	
	UPROPERTY()
	protected float HorizontalOffset = 10.0f;

	private FVector _ForwardVector;	// Used previously when we wanted to switch between camera forward and input forward.

	private bool bHadInput = false;

	private bool bIsMoving = false;

	bool IsMoving() const
	{
		return bIsMoving;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		devEnsure(Player != nullptr, "Not haze player, not cool");
	}

	bool IsTargetAvailable(AHazeActor InTarget)
	{
		return AvailableTargets.Contains(InTarget);
	}

	void UpdateForwardVector(FVector InForwardVector)
	{
		_ForwardVector = InForwardVector;
	}

	void UpdateTargets()
	{
		const bool bInputDown = !FMath::IsNearlyZero(_ForwardVector.Size());
		TargetsToRemove.Empty();

		if(bInputDown && !bHadInput)
		{
			NetSetIsMoving(true);
		}
		else if(!bInputDown && bHadInput)
		{
			NetSetIsMoving(false);
		}

		const FVector LocalLeftNormal = LeftNormal;
		const FVector LocalRightNormal = RightNormal;
		
		for(AHazeActor Target : AvailableTargets)
		{
			if(Target == nullptr)
				continue;

			const float DistanceSq = Target.ActorCenterLocation.DistSquared(StartLocation);

			if(DistanceSq > FMath::Square(_TomatoSettings.DashTargetRange) 
			|| !IsPointInsideCone(Target.ActorCenterLocation, LocalRightNormal, -LocalLeftNormal)
			|| !IsTomatoDashTargetValid(Target))
			{
				TargetsToRemove.Add(Target);
			}
		}

		for(AHazeActor Target : TargetsToRemove)
		{
			NetRemoveTarget(Target);
		}

		UHazeAITeam DashTargetTeam = HazeAIBlueprintHelper::GetTeam(n"TomatoDashTargetTeam");

		if(DashTargetTeam == nullptr)
			return;

		const TSet<AHazeActor>& Members = DashTargetTeam.GetMembers();

		for(AHazeActor Target : Members)
		{
			if(Target == nullptr)
				continue;
			
			const float DistanceSq = Target.ActorCenterLocation.DistSquared(StartLocation);

			if(!AvailableTargets.Contains(Target) && DistanceSq < FMath::Square(_TomatoSettings.DashTargetRange) 
			&& IsPointInsideCone(Target.ActorCenterLocation, LocalRightNormal, -LocalLeftNormal)
			&& IsTomatoDashTargetValid(Target))
			{
				NetAddTarget(Target);
			}
		}

		bHadInput = bInputDown;
		
		ClearNullTargets();
		SortAvailableTargets();
	}

	void ClearNullTargets()
	{
		for(int Index = AvailableTargets.Num() - 1; Index >= 0; --Index)
		{
			if(AvailableTargets[Index] == nullptr)
				AvailableTargets.RemoveAt(Index);
		}
	}

	bool IsClosestTarget(AHazeActor ActorToTest) const
	{
		return AvailableTargets.Num() > 0 && AvailableTargets[0] == ActorToTest && IsTomatoDashTargetValid(ActorToTest);
	}

	UFUNCTION(NetFunction)
	private void NetSetIsMoving(bool bValue)
	{
		bIsMoving = bValue;

		if(!bIsMoving)
		{
			AvailableTargets.Reset();
		}
	}

	void DrawDebug()
	{
		const float Length = _TomatoSettings.DashTargetRange;

		const FVector LocalRightStartLocation = RightStartLocation;
		const FVector LocalLeftStartLocation = LeftStartLocation;

		const FVector LocalRightOffset = RightOffset;
		const FVector LocalLeftOffset = LeftOffset;

		const float ArrowSize = 10.0f;
		System::DrawDebugArrow(LocalRightStartLocation, LocalRightStartLocation + (LocalRightOffset * Length), ArrowSize, FLinearColor::Green);
		System::DrawDebugArrow(LocalLeftStartLocation, LocalLeftStartLocation + (LocalLeftOffset * Length), ArrowSize, FLinearColor::Green);
	
		const float NormalLocationLength = Length * 0.5f;
		const float NormalLength = 30.0f;

		const FVector RightNormalStartLocation = LocalRightStartLocation + (LocalRightOffset * NormalLocationLength);
		const FVector LeftNormalStartLocation = LocalLeftStartLocation + (LocalLeftOffset * NormalLocationLength);

		System::DrawDebugArrow(RightNormalStartLocation, RightNormalStartLocation + (RightNormal * NormalLength), ArrowSize, FLinearColor::Red);
		System::DrawDebugArrow(LeftNormalStartLocation, LeftNormalStartLocation - (LeftNormal * NormalLength), ArrowSize, FLinearColor::Red);
	}

	UFUNCTION(NetFunction)
	private void NetAddTarget(AHazeActor InTarget)
	{
		if(InTarget == nullptr)
			return;

		AvailableTargets.AddUnique(InTarget);
	}

	UFUNCTION(NetFunction)
	private void NetRemoveTarget(AHazeActor InTarget)
	{
		AvailableTargets.Remove(InTarget);
	}

	void ClearTargets()
	{
		NetClearTargets();
	}

	UFUNCTION(NetFunction)
	private void NetClearTargets()
	{
		AvailableTargets.Reset();
	}

	bool IsPointInsideCone(FVector Point, FVector InRightNormal, FVector InLeftNormal) const
	{
		const FVector RightDirToTarget = (Point - RightStartLocation).GetSafeNormal();
		const FVector LeftDirToTarget = (Point - LeftStartLocation).GetSafeNormal();

		if(RightDirToTarget.DotProduct(InRightNormal) > 0.0f 
		|| LeftDirToTarget.DotProduct(InLeftNormal) > 0.0f)
		{
			return true;
		}

		return false;
	}

	private void SortAvailableTargets()
	{
		if(AvailableTargets.Num() < 2)
			return;
		
		const FVector Loc = StartLocation;

		int SortCount = AvailableTargets.Num();

		while(SortCount > 1)
		{
			for(int Index = 0; Index < (SortCount  - 1); ++Index)
			{
				const FVector LocA = AvailableTargets[Index].ActorCenterLocation;
				const FVector LocB = AvailableTargets[Index + 1].ActorCenterLocation;

				const float A = Loc.DistSquared2D(LocA);
				const float B = Loc.DistSquared2D(LocB);

				if(A > B)
				{
					AvailableTargets.Swap(Index, Index + 1);
				}
			}

			SortCount--;
		}
	}

	FVector GetStartLocation() const property
	{
		return Player.ActorCenterLocation;
	}

	FVector GetUpVector() const property
	{
		return FVector::UpVector;
	}

	FVector GetForwardVector() const property
	{
		return Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
	}

	FVector GetRightVector() const property
	{
		return ForwardVector.RotateAngleAxis(90.0f, UpVector);
	}

	FVector GetRightOffset() const property
	{
		return ForwardVector.RotateAngleAxis(_TomatoSettings.DashTargetAngle, UpVector);
	}

	FVector GetLeftOffset() const property
	{
		return ForwardVector.RotateAngleAxis(-_TomatoSettings.DashTargetAngle, UpVector);
	}

	FVector GetRightNormal() const property
	{
		return RightOffset.CrossProduct(UpVector).GetSafeNormal();
	}

	FVector GetLeftNormal() const property
	{
		return LeftOffset.CrossProduct(UpVector).GetSafeNormal();
	}

	FVector GetRightStartLocation() const property
	{
		return StartLocation + (RightVector * HorizontalOffset);
	}

	FVector GetLeftStartLocation() const property
	{
		return StartLocation - (RightVector * HorizontalOffset);
	}
}
