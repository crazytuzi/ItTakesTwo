import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
class ADeadVacuumHoseManager : AHazeActor
{
	UPROPERTY()
	TArray<AVacuumHoseActor> HoseArray;

	UPROPERTY()
	UAnimSequence HoseHeadAnim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// System::SetTimer(this, n"GiveImpulse", FMath::RandRange(3, 5), false);
		System::SetTimer(this, n"DelayedBeginPlay", FMath::RandRange(1, 2), false);

		// for (AVacuumHoseActor CurHose : HoseArray)
		// {
		// 	CurHose.EnableHose();
			
		// 	CurHose.BackHazeAkComp.PerformDisabled();
		// 	CurHose.FrontHazeAkComp.PerformDisabled();
			
		// 	CurHose.DisableInteraction(EVacuumMountLocation::Back);
		// 	CurHose.DisableInteraction(EVacuumMountLocation::Front);

		// 	FHazePlaySlotAnimationParams SuckParams;
       	// 	SuckParams.Animation = HoseHeadAnim;
        // 	SuckParams.BlendTime = 0.1f;
        // 	SuckParams.bLoop = true;

		// 	CurHose.SkeletalBackFace.PlaySlotAnimation(SuckParams);
			
		// 	CurHose.GetLastCollisionSphere().AddImpulseAtLocation(FVector(FMath::RandRange(-15000, 15000), FMath::RandRange(-15000, 15000), 0.f), CurHose.GetLastCollisionSphere().GetWorldLocation());
		// }
	}

	UFUNCTION()
	void DelayedBeginPlay()
	{
		for (AVacuumHoseActor CurHose : HoseArray)
		{
			CurHose.EnableHose();
			
			// CurHose.BackHazeAkComp.PerformDisabled();
			// CurHose.FrontHazeAkComp.PerformDisabled();
			
			CurHose.DisableInteraction(EVacuumMountLocation::Back);
			CurHose.DisableInteraction(EVacuumMountLocation::Front);

			FHazePlaySlotAnimationParams SuckParams;
       		SuckParams.Animation = HoseHeadAnim;
        	SuckParams.BlendTime = 0.1f;
        	SuckParams.bLoop = true;

			CurHose.SkeletalBackFace.PlaySlotAnimation(SuckParams);
			
			// CurHose.GetLastCollisionSphere().AddImpulseAtLocation(FVector(FMath::RandRange(-15000, 15000), FMath::RandRange(-15000, 15000), 0.f), CurHose.GetLastCollisionSphere().GetWorldLocation());
		}		
	}

	UFUNCTION()
	void GiveImpulse()
	{
		int RandomIndex = FMath::RandRange(0, HoseArray.Num() - 1);
		HoseArray[RandomIndex].GetLastCollisionSphere().AddImpulseAtLocation(FVector(FMath::RandRange(-15000, 15000), FMath::RandRange(-15000, 15000), 0.f), HoseArray[RandomIndex].GetLastCollisionSphere().GetWorldLocation());
		System::SetTimer(this, n"GiveImpulse", FMath::RandRange(1, 3), false);
	}
}