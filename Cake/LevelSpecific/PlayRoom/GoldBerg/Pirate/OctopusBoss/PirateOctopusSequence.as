import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusSlam;
struct FPirateOctopusArmSequencePoint
{
	APirateOctopusSequenceSlamArm CurrentArm = nullptr;
	FHazeSplineSystemPosition SplinePosition;
}


class UPirateOctopusSequenceComponent : UActorComponent
{
	int NumberOfPoints = 16;
	float MaxAngleForSpawning = 65;
	
	// Needs 3 in front and 3 behind to be valid
	int RequiredFreeSlots = 1;

	TArray<FPirateOctopusArmSequencePoint> Points;
	int ActiveArms = 0;

	APirateOctopusActor Boss;

	void Initialize(APirateOctopusActor BossActor, int MaxArms, int CustomNumberOfPoints = -1)
	{		
		if(CustomNumberOfPoints > 0)
			NumberOfPoints = CustomNumberOfPoints;
			
		Boss = BossActor;
		Points.SetNum(NumberOfPoints);
		const float SplineLength = BossActor.StreamSpline.Spline.GetSplineLength();
		const float Diff = SplineLength / NumberOfPoints;

		for (int i = 0; i < Points.Num(); ++i)
		{
			Points[i].SplinePosition.FromData(BossActor.StreamSpline.Spline,  i * Diff, true);
		}

		// Initialize the correct amount of arms
		TArray<APirateOctopusArm> ArmsToInitialize;
		ArmsToInitialize.Reserve(MaxArms);
		for(int i = 0; i < MaxArms; ++i)
		{
			ArmsToInitialize.Add(BossActor.ArmsContainerComponent.GetArm(BossActor.SecondSequenceSlamArmType));	
		}
		for(int i = 0; i < ArmsToInitialize.Num(); ++i)
		{
			BossActor.ArmsContainerComponent.ReleaseArm(ArmsToInitialize[i]);
		}
	}

	bool FindFreePointIndex(int LastActivatedIndex, int& OutFoundIndex) const
	{
		const int LastIndex = Points.Num() - 1;	

		int CurrentSearchIndex;
		if(LastActivatedIndex >= 0)
			CurrentSearchIndex = LastActivatedIndex + FMath::RandRange(-(RequiredFreeSlots * 2), (RequiredFreeSlots * 2));
		else
			CurrentSearchIndex = FMath::RandRange(0, LastIndex);

		for(int i = 0; i < 5; ++i)
		{	
			while(CurrentSearchIndex > LastIndex)
				CurrentSearchIndex -= LastIndex;
			while(CurrentSearchIndex < 0)
				CurrentSearchIndex += LastIndex;

			if(SearchInternal(CurrentSearchIndex, OutFoundIndex))
				return true;

			CurrentSearchIndex += FMath::RandRange(1, RequiredFreeSlots * 4);
		}

		return false;
	}

	bool FindFreePointClosestToBoatPosition(FVector BoatLocation, int& OutFoundIndex)
	{
		int BestIndex = -1;
		float ClosestDistance = BIG_NUMBER;
		for(int i = 0; i < Points.Num(); ++i)
		{
			if(Points[i].CurrentArm != nullptr)
				continue;

			float DistSq = BoatLocation.DistSquared(Points[i].SplinePosition.WorldLocation);
			if(DistSq < ClosestDistance)
			{
				ClosestDistance = DistSq;
				BestIndex = i;
			}
		}

		if(BestIndex >= 0)
		{
			OutFoundIndex = BestIndex;
			return true;
		}

		return false;
	}

	bool FindFreePointClosestToBoatDirection(FTransform BoatTransform, int& OutFoundIndex)
	{
		int BestIndex = -1;
		float ClosestAngle = -1;
		const FVector BoatLocation = BoatTransform.Location;
		const FVector BoatDirection = BoatTransform.Rotation.ForwardVector;
		for(int i = 0; i < Points.Num(); ++i)
		{
			if(Points[i].CurrentArm != nullptr)
				continue;

			const FVector DirToPoint = (Points[i].SplinePosition.WorldLocation - BoatLocation).GetSafeNormal();
			float DotAngle = DirToPoint.DotProduct(BoatDirection);
			if(DotAngle > ClosestAngle)
			{
				BestIndex = i;
				ClosestAngle = DotAngle;
			}

			// Close enough
			if(ClosestAngle >= 1 - KINDA_SMALL_NUMBER)
				break;
		}

		if(BestIndex >= 0)
		{
			OutFoundIndex = BestIndex;
			return true;
		}

		return false;
	}

	int GetNextPointIndex(int FromIndex, int Offset = 1)
	{
		int WantedIndex = FromIndex + Offset;

		while(WantedIndex >= Points.Num())
			WantedIndex -= Points.Num();
		while(WantedIndex < 0)
			WantedIndex += Points.Num();

		return WantedIndex;	
	}

	bool SearchInternal(int FromIndex, int& OutFoundIndex) const
	{
		const int LastIndex = Points.Num() - 1;	
		int CurrentSearchIndex = FromIndex;
		int LastValidIndex = -1;
		int FoundFreeSlots = 0;

		for(int i = 0; i <= LastIndex; ++i)
		{
			if(CurrentSearchIndex > LastIndex)
				CurrentSearchIndex = 0;

			if(Points[CurrentSearchIndex].CurrentArm == nullptr)
			{
				FoundFreeSlots++;
				if(FoundFreeSlots == RequiredFreeSlots + 1)
					LastValidIndex = CurrentSearchIndex;
			}
			else
			{
				FoundFreeSlots = 0;
			}

			// Requires the amount in front and behind + the current one
			if(FoundFreeSlots == (RequiredFreeSlots * 2) + 1)
			{
				if(Boss.WheelBoat != nullptr)
				{
					const FVector ArmLocation = Points[LastValidIndex].SplinePosition.GetWorldLocation();
					const FVector BoatLocation = Boss.WheelBoat.GetActorLocation();

					const FVector DirToArm = (ArmLocation - BoatLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
					const float AngleToArm = Math::DotToDegrees(DirToArm.DotProduct(Boss.WheelBoat.GetActorForwardVector()));
					if(AngleToArm > MaxAngleForSpawning)
						return false;
				}

				OutFoundIndex = LastValidIndex;
				return true;
			}

			CurrentSearchIndex++;
		}

		return false;
	}

	void SetArmAtPosition(int PositionIndex, APirateOctopusSequenceSlamArm Arm, float LerpTime = -1)
	{
		Arm.SequencePointIndex = PositionIndex;
		ensure(Points[PositionIndex].CurrentArm == nullptr);
		ensure(Arm != nullptr);
		Points[PositionIndex].CurrentArm = Arm;
		Arm.SetArmPosition(Points[PositionIndex].SplinePosition.WorldLocation, CustomLerpTime = LerpTime);
		ActiveArms++;
	}

	FVector GetArmPosition(int PositionIndex)
	{
		FVector Position;
		Position = Points[PositionIndex].SplinePosition.WorldLocation;
		return Position;
	}

	void RemoveArmFromPoint(APirateOctopusSequenceSlamArm Arm)
	{
		if(Arm.SequencePointIndex >= 0)
		{
			ensure(Points[Arm.SequencePointIndex].CurrentArm == Arm);
			Points[Arm.SequencePointIndex].CurrentArm = nullptr;
			Arm.SequencePointIndex = -1;
			ActiveArms--;
		}
	}

	int GetActiveArmsCount()const
	{
		return ActiveArms;
	}
}

UCLASS(Abstract)
class APirateOctopusSequenceSlamArm : APirateOctopusSlam //not used
{
	UPROPERTY()
	float OffsetTowardBoatAmount = 0.f;

	int SequencePointIndex = -1;

	FVector GetWantedWorldPosition(FVector WorldPosition) const override
	{
		FVector FinalWorldPosition = WorldPosition;
		FVector DirToTarget = (PlayerTarget.GetActorLocation() - WorldPosition).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FinalWorldPosition += DirToTarget * OffsetTowardBoatAmount;
		return FinalWorldPosition;
	}
}

