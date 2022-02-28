import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusArm;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Peanuts.Spline.SplineComponent;


struct FPirateOctopusArmCreateData
{
	TSubclassOf<APirateOctopusArm> Type;
	TArray<APirateOctopusArm> FreeArms;
	TArray<APirateOctopusArm> CurrentlyActiveArms;
};


class UPirateOctopusArmsContainerComponent : UActorComponent
{
	TArray<FPirateOctopusArmCreateData> ArmTypes;

	AHazeActor BossOwner;
	AWheelBoatActor WheelBoat;
	UHazeSplineComponent Stream;
	private int ArmCount = 0;

	void Initialize(AWheelBoatActor WheelBoatTarget, UHazeSplineComponent StreamComponent)
	{
		BossOwner = Cast<AHazeActor>(Owner);
		WheelBoat = WheelBoatTarget;
		Stream = StreamComponent;
	}

	void InitializeArm(TSubclassOf<APirateOctopusArm> ArmType)
	{
		APirateOctopusArm Arm = GetArm(ArmType);
		ReleaseArm(Arm);
	}

	void Clear()
	{
		for(FPirateOctopusArmCreateData& ArmType : ArmTypes)
		{
			for(APirateOctopusArm Arm : ArmType.FreeArms)
			{
				if(Arm != nullptr)
					Arm.DestroyActor();
			}

			ArmType.FreeArms.Empty();

			for(APirateOctopusArm Arm : ArmType.CurrentlyActiveArms)
			{
				if(Arm != nullptr)
					Arm.DestroyActor();
			}

			ArmType.CurrentlyActiveArms.Empty();
		}
	}

	APirateOctopusArm GetArm(TSubclassOf<APirateOctopusArm> ArmType)
	{
		if(!ArmType.IsValid())
			return nullptr;

		for(FPirateOctopusArmCreateData& ArmTypeIndex : ArmTypes)
		{
			if(ArmTypeIndex.Type.Get() == ArmType.Get())
			{
				// if(ArmTypeIndex.FreeArms.Num() > 0)
				// {	
				// 	// Get the free arm
				// 	ArmTypeIndex.CurrentlyActiveArms.Add(ArmTypeIndex.FreeArms.Last());
				// 	ArmTypeIndex.FreeArms.RemoveAt(ArmTypeIndex.FreeArms.Num() - 1);
				// 	return ArmTypeIndex.CurrentlyActiveArms[ArmTypeIndex.CurrentlyActiveArms.Num() - 1];
				// }
				// else
				// {
					// We need more arms so add one
					APirateOctopusArm ArmActor = Cast<APirateOctopusArm>(SpawnActor(ArmType, BossOwner.ActorLocation, BossOwner.ActorRotation, bDeferredSpawn = true));
					ArmActor.MakeNetworked(this, ArmCount);
					ArmCount++;
					ArmActor.FinishSpawningActor();
					ArmActor.Initialize(BossOwner, Stream);
					ArmTypeIndex.CurrentlyActiveArms.Add(ArmActor);
					return ArmTypeIndex.CurrentlyActiveArms[ArmTypeIndex.CurrentlyActiveArms.Num() - 1];
				//}
			}
		}

		// Create the new arm type
		APirateOctopusArm ArmActor = Cast<APirateOctopusArm>(SpawnActor(ArmType, BossOwner.ActorLocation, BossOwner.ActorRotation, bDeferredSpawn = true));
		ArmActor.MakeNetworked(this, ArmCount);
		ArmCount++;
		ArmActor.FinishSpawningActor();
		ArmActor.Initialize(BossOwner, Stream);
		FPirateOctopusArmCreateData NewType;
		NewType.Type = ArmType;
		NewType.CurrentlyActiveArms.Add(ArmActor);
		ArmTypes.Add(NewType);

		return ArmActor;
	}

	void ReleaseArm(APirateOctopusArm Arm)
	{
		if(Arm == nullptr)
			return;

		for(FPirateOctopusArmCreateData& ArmTypeIndex : ArmTypes)
		{
			if(ArmTypeIndex.Type.Get() == Arm.Class)
			{
				ArmTypeIndex.CurrentlyActiveArms.Remove(Arm);
				ArmTypeIndex.FreeArms.Add(Arm);
				return;
			}
		}
	}
}

