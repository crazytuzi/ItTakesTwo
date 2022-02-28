import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

struct FSapAttachTarget
{
	UPROPERTY()
	FVector RelativeLocation = FVector::ZeroVector;

	UPROPERTY()
	FVector RelativeNormal = FVector::ZeroVector;

	UPROPERTY()
	USceneComponent Component = nullptr;

	UPROPERTY()
	FName Socket = NAME_None;

	UPROPERTY()
	bool bIsAutoAim = false;

	UPROPERTY()
	FVector WorldOffset = FVector::ZeroVector;

	bool IsValid() const
	{
		// Never valid to attach to disabled actors
		auto HazeActor = Cast<AHazeActor>(Actor);
		if (HazeActor != nullptr && HazeActor.IsActorDisabled())
			return false;

		auto SwarmComp = Cast<USwarmSkeletalMeshComponent>(Component);
		if (SwarmComp != nullptr)
		{
			// For swarms, we want to make sure the swarm is alive
			return !SwarmComp.bAboutToDie;
		}
		else
		{
			// Otherwise, just check if we have a component
			return Component != nullptr;
		}
	}

	FVector GetWorldLocation() const property
	{
		return GetParentTransform().TransformPosition(RelativeLocation) + WorldOffset;
	}

	void SetWorldLocation(FVector InWorldLocation) property
	{
		RelativeLocation = GetParentTransform().InverseTransformPosition(InWorldLocation - WorldOffset);
	}

	FVector GetWorldNormal() const property
	{
		return GetParentTransform().TransformVector(RelativeNormal);
	}

	void SetWorldNormal(FVector InWorldNormal) property
	{
		RelativeNormal = GetParentTransform().InverseTransformVector(InWorldNormal);
	}

	FTransform GetParentTransform() const property
	{
		if (Component != nullptr)
		{
			if (Socket != NAME_None)
				return Component.GetSocketTransform(Socket);
			else
				return Component.WorldTransform;
		}

		return FTransform();
	}

	AActor GetActor() const property
	{
		if (Component == nullptr)
			return nullptr;

		return Component.Owner;
	}

	bool CanReach(FSapAttachTarget Other) const
	{
		return Component == Other.Component;
	}

	float DistSquared(FSapAttachTarget Other) const
	{
		return GetWorldLocation().DistSquared(Other.WorldLocation);
	}

	int GetAttachedBoneIndex() const
	{
		auto SkelMesh = Cast<USkeletalMeshComponent>(Component);
		if (Socket != NAME_None && SkelMesh != nullptr)
		{
			return SkelMesh.GetBoneIndex(Socket);
		}

		return -1;
	}

	void SetSocketFromBoneIndex(int Index)
	{
		auto SkelMesh = Cast<USkeletalMeshComponent>(Component);
		if (Index >= 0 && SkelMesh != nullptr)
		{
			Socket = SkelMesh.GetBoneName(Index);
		}
	}

	void SetFromHit(FHitResult Hit)
	{
		bIsAutoAim = false;
		WorldOffset = FVector::ZeroVector;

		if (Hit.bBlockingHit)
		{
			Component = Hit.Component;
			Socket = Hit.BoneName;

			if (Socket != NAME_None)
			{
				FTransform SocketTransform = Hit.Component.GetSocketTransform(Hit.BoneName);
				RelativeLocation = SocketTransform.InverseTransformPosition(Hit.Location);
				RelativeNormal = SocketTransform.InverseTransformVector(Hit.ImpactNormal);
			}
			else
			{
				RelativeLocation = Component.WorldTransform.InverseTransformPosition(Hit.Location);
				RelativeNormal = Component.WorldTransform.InverseTransformVector(Hit.ImpactNormal);
			}
		}
		else
		{
			Component = nullptr;
			RelativeLocation = Hit.TraceEnd;
			RelativeNormal = FVector::ZeroVector;
			Socket = NAME_None;
		}
	}

	bool HasAttachParent() const
	{
		// Never valid to attach to disabled actors
		auto HazeActor = Cast<AHazeActor>(Actor);
		if (HazeActor != nullptr && HazeActor.IsActorDisabled())
			return false;

		auto SwarmComp = Cast<USwarmSkeletalMeshComponent>(Component);
		if (SwarmComp != nullptr)
		{
			// For swarms, we want to make sure the swarm is alive
			return !SwarmComp.bAboutToDie;
		}
		else
		{
			// Otherwise, just check if we have a component
			return Component != nullptr;
		}
	}
}

// Blueprint bindings...
UFUNCTION(BlueprintPure, Category="Sap|AttachTarget", meta=(DisplayName=GetWorldLocation))
FVector SapAttachTarget_WorldLocation(FSapAttachTarget Target)
{
	return Target.WorldLocation;
}
UFUNCTION(BlueprintPure, Category="Sap|AttachTarget", meta=(DisplayName=GetActor))
AActor SapAttachTarget_GetActor(FSapAttachTarget Target)
{
	return Target.Actor;
}

namespace FSapAttachTarget
{
	FSapAttachTarget Lerp(FSapAttachTarget A, FSapAttachTarget B, float Alpha)
	{
		// Convert to world space...
		FVector WorldLocation = A.WorldLocation;
		FVector WorldNormal = A.WorldNormal;

		// Lerp the world location...
		WorldLocation = FMath::Lerp(WorldLocation, B.WorldLocation, Alpha);
		WorldNormal = Math::SlerpVectorTowards(WorldNormal, B.WorldNormal, Alpha);

		// Finally setup the result
		// The component, socket, auto-aim etc will be chosen from B
		FSapAttachTarget Result = B;
		Result.WorldLocation = WorldLocation;
		Result.WorldNormal = WorldNormal;

		return Result;
	}
}