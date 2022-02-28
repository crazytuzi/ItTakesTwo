import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;
import Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeDisableComponent;



class UHarpoonBoatMovementComponent : USceneComponent
{
	// Make sure that we are ticking before gameplay and after the player has moved
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_HazeAnimation;

	const float MovementTime = 5.f;
	const float MaxHeightOffset = 32.f;
	const FHazeMinMax RollOffset = FHazeMinMax(-0.5f, 0.5f);

	UPROPERTY(Transient, EditConst)
	bool bHasDeactivatedActor = false;

	AHarpoonBoatActor OwnerBoat;
	AHazePlayerCharacter LastPlayerThatCouldSee;

	float MovementAmount = 0;
	FVector StartLoc;
	FRotator StartRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwnerBoat = Cast<AHarpoonBoatActor>(Owner);
		LastPlayerThatCouldSee = Game::GetMay();
		bHasDeactivatedActor = true;

		StartLoc = GetWorldLocation();
		StartRot = GetWorldRotation();
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MovementAmount = Math::FWrap(MovementAmount + DeltaSeconds, 0.f, MovementTime);
		if(IsVisible())
		{
			UpdateMovement(DeltaSeconds);
		}
	}

	void UpdateMovement(float DeltaSeconds)
	{
		const float Median = MovementTime * 0.5f;
		float MoveAlpha = MovementAmount / Median;
		if(MoveAlpha >= 1.f)
		 	MoveAlpha = 2.f - MoveAlpha;

		FVector NewLocation = StartLoc;
		NewLocation.Z += FMath::EaseInOut(0.f, MaxHeightOffset, MoveAlpha, 2.f);

		FRotator NewRotation = StartRot;
		const float RotationOffset = FMath::Lerp(RollOffset.Min, RollOffset.Max, FMath::EaseInOut(0.f, 1.f, MoveAlpha, 2.f));
		NewRotation.Yaw += RotationOffset;
		NewRotation.Pitch += RotationOffset;

		NewLocation = FMath::VInterpTo(GetWorldLocation(), NewLocation, DeltaSeconds, 7.f);
		NewRotation = FMath::RInterpTo(GetWorldRotation(), NewRotation, DeltaSeconds, 10.f);
		OwnerBoat.SetActorLocationAndRotation(NewLocation, NewRotation);
	}

	bool IsVisible()
	{
		auto Cody = Game::Cody;
		auto May = Game::May;
		
		bool bAnyPlayerCanSee = OwnerBoat.MeshComp.WasRecentlyRendered(1.f);
		if(!bAnyPlayerCanSee)
		{	
			if(SceneView::ViewFrustumBoxIntersection(LastPlayerThatCouldSee, OwnerBoat.VisualBoarder))
			{
				bAnyPlayerCanSee = true;
			}
			else if(SceneView::ViewFrustumBoxIntersection(LastPlayerThatCouldSee.GetOtherPlayer(), OwnerBoat.VisualBoarder))
			{
				bAnyPlayerCanSee = true;
				LastPlayerThatCouldSee = LastPlayerThatCouldSee.GetOtherPlayer();
			}
		}

		return bAnyPlayerCanSee;
	}
}


class AHarpoonBoatActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHarpoonBoatMovementComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeStaticMeshComponent MeshComp;
	default MeshComp.bCanBeDisabled = false;
	default MeshComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTrace, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
    USnowGlobeLakeDisableComponentExtension DisableExtension;
    default DisableExtension.ActiveType = ESnowGlobeLakeDisableType::ActiveOnSurface;

	UPROPERTY(DefaultComponent, Attach = DisableExtension)
	UBoxComponent VisualBoarder;
	default VisualBoarder.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bCollideWhileDisabled = true;

	UPROPERTY(Category = "Setup")
	AMagnetHarpoonActor MagnetHarpoon1; 

	UPROPERTY(Category = "Setup")
	AMagnetHarpoonActor MagnetHarpoon2; 

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if(MagnetHarpoon1 != nullptr)
		{
			Disable.DisableLinkedActors.AddUnique(MagnetHarpoon1);
		}

		if(MagnetHarpoon2 != nullptr)
		{
			Disable.DisableLinkedActors.AddUnique(MagnetHarpoon2);
		}
    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagnetHarpoon1.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
		MagnetHarpoon2.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
	
	}
}