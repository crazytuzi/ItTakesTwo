import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossMayExplosionComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBosExplosionDebrisStatics;
import Vino.Checkpoints.Statics.CheckpointStatics;

event void FLandedOnDebris();

class AClockworkLastBossExplosionDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent CheckpointLocation;
	default CheckpointLocation.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = CheckpointLocation)
	UHazeSkeletalMeshComponentBase PreviewCheckpointLocation;
	default PreviewCheckpointLocation.bHiddenInGame = true;
	default PreviewCheckpointLocation.bIsEditorOnly = true;
	default PreviewCheckpointLocation.CollisionEnabled = ECollisionEnabled::NoCollision;
	
	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent Impacts;
	
	UPROPERTY()
	TArray<UStaticMesh> MeshArray;

	UPROPERTY()
	ACheckpoint ConnectedCheckpoint;

	UPROPERTY()
	AClockworkLastBossExplosionDebris ConnectedDebris;

	UPROPERTY()
	EDebrisType DebrisType = EDebrisType::A;

	UPROPERTY()
	bool bFlipCheckpointLocation = false;

	UPROPERTY()
	FLandedOnDebris LandedOnDebrisEvent;

	UPROPERTY()
	bool bShouldPostEvent = false;

	UPROPERTY()
	bool bDebugMode = false;

	UPROPERTY()
	int32 DebrisProgressionIndex;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Impacts.OnActorDownImpactedByPlayer.AddUFunction(this, n"PlayerLandedOnDebris");
		Impacts.OnActorForwardImpactedByPlayer.AddUFunction(this, n"ForwardPlayerLandedOnDebris");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// switch(DebrisType)
		// {
		// 	case EDebrisType::A:
		// 		Mesh.SetStaticMesh(MeshArray[DebrisType]);
		// 		if (bFlipCheckpointLocation)
		// 		{
		// 			CheckpointLocation.SetRelativeLocation(FVector(0.f, 0.f, -4.f));
		// 			CheckpointLocation.SetRelativeRotation(FRotator(0.f, 0.f, 180.f));
		// 		} else 
		// 		{
		// 			CheckpointLocation.SetRelativeLocation(FVector(0.f, 0.f, 100.f));
		// 			CheckpointLocation.SetRelativeRotation(FRotator::ZeroRotator);
		// 		}
		// 		break;

		// 	case EDebrisType::B:
		// 		Mesh.SetStaticMesh(MeshArray[DebrisType]);
		// 		if (bFlipCheckpointLocation)
		// 		{
		// 			CheckpointLocation.SetRelativeLocation(FVector(-350.f, 60.f, 290.f));
		// 			CheckpointLocation.SetRelativeRotation(FRotator(90.f, -150.f, -150.f));
		// 		} else
		// 		{
		// 			CheckpointLocation.SetRelativeLocation(FVector(-250.f, 60.f, 290.f));
		// 			CheckpointLocation.SetRelativeRotation(FRotator(-90.f, 0.f, 0.f));
		// 		}
		// 		break;

		// 	case EDebrisType::C:
		// 		Mesh.SetStaticMesh(MeshArray[DebrisType]);
		// 		if (bFlipCheckpointLocation)
		// 		{
		// 			CheckpointLocation.SetRelativeLocation(FVector(-170.f, -110.f, -4.f));
		// 			CheckpointLocation.SetRelativeRotation(FRotator(0.f, 0.f, 180.f));
		// 		} else
		// 		{
		// 			CheckpointLocation.SetRelativeLocation(FVector(-170.f, -110.f, 100.f));
		// 			CheckpointLocation.SetRelativeRotation(FRotator::ZeroRotator);
		// 		}
		// 		break;

		// 		case EDebrisType::D:
		// 		Mesh.SetStaticMesh(MeshArray[DebrisType]);
		// 		if (bFlipCheckpointLocation)
		// 		{
		// 			CheckpointLocation.SetRelativeLocation(FVector(-580.f, -190.f, 10.f));
		// 			CheckpointLocation.SetRelativeRotation(FRotator(-90.f, 56.f, 33.f));
		// 		} else
		// 		{
		// 			CheckpointLocation.SetRelativeLocation(FVector(-580.f, -230.f, 10.f));
		// 			CheckpointLocation.SetRelativeRotation(FRotator(-90.f, 180.f, 91.f));
		// 		}
		// 		break;
		// }

		if (ConnectedCheckpoint != nullptr)
		{
			PreviewCheckpointLocation.SetVisibility(false);

			if (ConnectedCheckpoint.GetAttachParentActor() == nullptr)
				ConnectedCheckpoint.AttachToComponent(CheckpointLocation, n"", EAttachmentRule::SnapToTarget);
			
		} else 
		{
			PreviewCheckpointLocation.SetVisibility(true);
		}
	}

	UFUNCTION()
	void PlayerLandedOnDebris(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		if (bDebugMode)
		{
			Print("Impact!", 2.f);
		}

		if (ConnectedCheckpoint != nullptr)
		{
			DisableAllCheckpointsForPlayer(Player);
			ConnectedCheckpoint.EnableForPlayer(Player);
		}

		ClockworkLastBoss::SetNewExplosionFocus(Player, ConnectedDebris);	

		if (bShouldPostEvent)
			LandedOnDebrisEvent.Broadcast();

		Player.OtherPlayer.SetCapabilityAttributeObject(n"AudioDebrisProgression", this);
	}

	UFUNCTION()
	void ForwardPlayerLandedOnDebris(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		Player.OtherPlayer.SetCapabilityAttributeObject(n"AudioDebrisProgression", this);
	}
}