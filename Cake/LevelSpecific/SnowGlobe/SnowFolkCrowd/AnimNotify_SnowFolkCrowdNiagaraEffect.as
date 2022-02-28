import Cake.LevelSpecific.SnowGlobe.SnowFolkCrowd.SnowFolkCrowdMember;

class UAnimNotify_SnowFolkCrowdNiagaraEffect : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SnowFolkCrowdNiagaraEffect";
	}
	
	// Niagara System to Spawn
	UPROPERTY(Category = "AnimNotify", meta = (DisplayName = "Niagara System"))
	UNiagaraSystem Template;

	// Location offset from the socket
	UPROPERTY(Category = "AnimNotify")
	FVector LocationOffset;

	// Rotation offset from socket
	UPROPERTY(Category = "AnimNotify")
	FRotator RotationOffset;

	// Scale to spawn the Niagara system at
	UPROPERTY(Category = "AnimNotify")
	FVector Scale;

	UPROPERTY(Category = "AnimNotify")
	bool bAttached;

	UPROPERTY(Category = "AnimNotify")
	FName SocketName;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		ASnowFolkCrowdMember Folk = Cast<ASnowFolkCrowdMember>(MeshComp.Owner);
		if (Folk == nullptr)
		{
			SpawnAt(MeshComp);
			return true;
		}

		SpawnForFolk(Folk);
		return true;
	}

	void SpawnForFolk(ASnowFolkCrowdMember Folk) const
	{
		SpawnAt(Folk.SkeletalMeshComponent);

		// Propegate to children
		TArray<AActor> Children;
		Folk.GetAttachedActors(Children);

		for(auto& Child : Children)
		{
			ASnowFolkCrowdMember CrowdMember = Cast<ASnowFolkCrowdMember>(Child);
			if(CrowdMember == nullptr)
				continue;

			SpawnForFolk(CrowdMember);
		}
	}

	void SpawnAt(USkeletalMeshComponent SkelMesh) const
	{
		if (bAttached)
		{
			Niagara::SpawnSystemAttached(Template, SkelMesh, SocketName, LocationOffset, RotationOffset, EAttachLocation::KeepRelativeOffset, true);
		}
		else
		{
			FTransform Spawn = FTransform(RotationOffset, LocationOffset) * SkelMesh.GetSocketTransform(SocketName);
			Niagara::SpawnSystemAtLocation(Template, Spawn.Location, Spawn.Rotation.Rotator(), Scale, true);
		}
	}
}