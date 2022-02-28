class UPlayerCollisionCapability : UHazeCollisionEnableCapability
{
	default CapabilityTags.Add(CapabilityTags::Collision);
	default CapabilityTags.Add(CapabilityTags::CollisionAndOverlap);

	int BlockCollisionCounter = 0;
	int BlockAllCollisionCounter = 0;

 	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		SetupCollisions(Player.CapsuleComponent, n"PlayerCharacterOverlapOnly");
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		if(Tag == CapabilityTags::Collision)
		{
			BlockCollisionCounter++;
			if(BlockCollisionCounter == 1)
			{
				SetDeactiveCollisionProfile();
			}
		}
		else if(Tag == CapabilityTags::CollisionAndOverlap)
		{
			BlockAllCollisionCounter++;	
			if(BlockAllCollisionCounter == 1)
			{
				SetDeactiveCollisionProfile();
				SetCollisionActive(false);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		if(Tag == CapabilityTags::Collision)
		{
			BlockCollisionCounter--;
		}
		else if(Tag == CapabilityTags::CollisionAndOverlap)
		{
			BlockAllCollisionCounter--;
			if(BlockAllCollisionCounter == 0)
			{
				SetCollisionActive(true);
			}
		}

		if(BlockCollisionCounter == 0 && BlockAllCollisionCounter == 0)
		{
			SetActiveCollisionProfile();
		}
	}
}