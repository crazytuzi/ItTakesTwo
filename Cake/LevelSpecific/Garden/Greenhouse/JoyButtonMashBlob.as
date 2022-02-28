import Cake.LevelSpecific.Garden.Greenhouse.Joy;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;

event void FOnBlobDestroyed();
event void FOnBlobActivated();
event void FOnBlobDeactivated();


class UJoyBlobSickleCuttableComponent : USickleCuttableHealthComponent
{
	float VerticalDistance;
	

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const override
	{
		FVector QueryFoward = Query.Transform.Rotation.ForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		//System::DrawDebugArrow(Query.Transform.Location, Query.Transform.Location + (QueryFoward * 500));
		FVector DirrToPoint = Query.Transform.Location - Player.GetActorLocation();
		DirrToPoint = DirrToPoint.ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		if(QueryFoward.DotProduct(DirrToPoint) >= 0.2f)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		const float VerticalDistanceUpper = Query.Transform.Location.Z - Player.ActorLocation.Z;
		if(bOwnerForcesDeactivation == true)
			return EHazeActivationPointStatusType::Invalid;


		if(VerticalDistanceUpper <= 900)
			return EHazeActivationPointStatusType::Valid;

		const EHazeActivationPointStatusType WantedStatus = Super::SetupActivationStatus(Player, Query);
		if(WantedStatus != EHazeActivationPointStatusType::Valid)
			return WantedStatus;

		if(MaxVerticalDistance < 0)
			return WantedStatus;

		const float VerticalDistanceLocal = Query.Transform.Location.Z - Player.ActorLocation.Z;
		const float VerticalAbsDistanceLocal = FMath::Abs(VerticalDistanceLocal);

		if(VerticalDistanceLocal <= 0)
			return EHazeActivationPointStatusType::Valid;

		if(VerticalAbsDistanceLocal <= MaxVerticalDistance)
			return EHazeActivationPointStatusType::Valid;

		return EHazeActivationPointStatusType::Invalid;
	}	


	bool ApplyDamage(int DamageAmount, AHazePlayerCharacter DamageInstigator, bool _bInvulnerable) override
	{
		if(bOwnerIsDead)
			return false;

		auto BlobOwner = Cast<AJoyButtonMashBlob>(Owner);
		if(!_bInvulnerable)
		{
			BlobOwner.SetAnimBoolParam(n"TookDamage", true);
		}

		const bool bValidStatus = Super::ApplyDamage(DamageAmount, DamageInstigator, _bInvulnerable);
		if(Health <= 0)
		{
			BlobOwner.Explode();
		}

		return bValidStatus;
	}


}

class AJoyButtonMashBlob : AHazeCharacter
{
	default CapsuleComponent.bGenerateOverlapEvents = false;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UJoyBlobSickleCuttableComponent SickleHealthComponent;
	default SickleHealthComponent.bInvulnerable = true;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent OptionalButtonStartLocation;
	UPROPERTY()
	FOnBlobDestroyed OnBlobDestroyed;
	UPROPERTY()
	FOnBlobActivated OnBlobActivated;
	UPROPERTY()
	FOnBlobDeactivated OnBlobDeactivated;
	UPROPERTY()
	AJoy Joy;
	UPROPERTY()
	int ThisPodsButtonMashPhase;
	float ButtonMashProgress = 0;
	UPROPERTY()
	EBlobLocations BlobLocation = EBlobLocations::RightHand;

	UFUNCTION(BlueprintEvent)
	void BP_OnBlobExplode()
	{}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SickleHealthComponent.bOwnerForcesDeactivation = true;
		if(BlobLocation == EBlobLocations::RightHand)
		{
			AttachToComponent(Joy.Mesh, Joy.Mesh.GetSocketBoneName(n"RightHand"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
			AddActorLocalOffset(FVector(0, 0, 100));
		}
		if(BlobLocation == EBlobLocations::Back)
		{
			AttachToComponent(Joy.Mesh, n"BackpackSocket", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
			//AddActorLocalOffset(FVector(0, -55, 170));
			//AddActorLocalRotation(FRotator(0, 10, 0));
		}
		if(BlobLocation == EBlobLocations::Head)
		{
			AttachToComponent(Joy.Mesh, n"HeadBlobSocket", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		 	//AddActorLocalOffset(FVector(0, 0, 20));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Joy == nullptr)
			return;

		if(!Joy.bButtonMashActive)
			return;

		if(ThisPodsButtonMashPhase != Joy.Phase)
			return;

		if(ButtonMashProgress >= 0.35f)
		{
			SickleHealthComponent.bInvulnerable = false;
		}
		else
		{
			SickleHealthComponent.bInvulnerable = true;
		}
			
		//PrintToScreen("ButtonMashProgressaaa " + ButtonMashProgress);
		ButtonMashProgress = Joy.fInterpFloatBlob;
	}

	void Explode()
	{
		OnBlobDestroyed.Broadcast();
		SickleHealthComponent.bOwnerIsDead = true;	
		SickleHealthComponent.bOwnerForcesDeactivation = true;
		BP_OnBlobExplode();
	}
	UFUNCTION()
	void DestroyBlobActor()
	{
		DestroyActor();
	}


	UFUNCTION()
	void ActivateBlob()
	{
		if(this.HasControl())
		{
			NetActivateBlob();
		}
	}
	UFUNCTION(NetFunction)
	void NetActivateBlob()
	{
		SickleHealthComponent.bOwnerForcesDeactivation = false;
		SickleHealthComponent.bInvulnerable = false;
		OnBlobActivated.Broadcast();
	}

	UFUNCTION()
	void DeactivateBlob()
	{
		if(this.HasControl())
		{
			NetDeactivateBlob();
		}
	}
	UFUNCTION(NetFunction)
	void NetDeactivateBlob()
	{
		SickleHealthComponent.bOwnerForcesDeactivation = true;
		SickleHealthComponent.bInvulnerable = true;
		OnBlobDeactivated.Broadcast();
	}

	UFUNCTION()
	void ManuallyDestroyBlob()
	{
		if(this.HasControl())
		{
			NetManuallyDestroyBlob();
		}
	}
	UFUNCTION(NetFunction)
	void NetManuallyDestroyBlob()
	{
		DestroyActor();
	}
}

enum EBlobLocations
{
	RightHand,
	Back,
	Head
}

