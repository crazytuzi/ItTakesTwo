

UFUNCTION(BlueprintPure)
bool GetBurstForceFeaturePart(UHazeCharacterSkeletalMeshComponent SkelMeshComp, FName PartName, FBurstForceFeaturePart& OutFoundData)
{
	if(SkelMeshComp == nullptr)
		return false;

	if(PartName == NAME_None)
		return false;

	UHazeLocomotionFeatureBase BaseFeature = SkelMeshComp.GetFeatureByClass(UBurstForceFeature::StaticClass());
	UBurstForceFeature Feature = Cast<UBurstForceFeature>(BaseFeature);
	if(Feature == nullptr)
		return false;

	if(!Feature.Features.Find(PartName, OutFoundData))
		return false;

	return true;
}

UFUNCTION(BlueprintPure, Category = "AnimationFeature", meta = (HidePin="Instance", DefaultToSelf = "Instance"))
FHazePlaySequenceData GetBurstForceAnimation(UHazeCharacterAnimInstance Instance)
{
	if(Instance != nullptr)
	{
		AActor Owner = Instance.GetOwningActor();
		if(Owner != nullptr)
		{
			UHazeBurstForceComponent BurstComp = UHazeBurstForceComponent::Get(Owner);
			if(BurstComp != nullptr)
			{
				return BurstComp.GetActiveAnimation();
			}
		}
	}

	return FHazePlaySequenceData();
}


UFUNCTION(BlueprintCallable)
void AddBurstForce(AHazeActor Actor, 
	FVector Force, 
	FRotator FaceRotation, 
	FBurstForceFeaturePart OptionalFeature = FBurstForceFeaturePart()
)
{
	if(Actor == nullptr)
		return;

	const FVector WorldUp = Actor.GetMovementWorldUp();
	UHazeBurstForceComponent BurstComp = UHazeBurstForceComponent::GetOrCreate(Actor);
	FHazeBurstAddForceData BurstForce;
	BurstForce.ForceType = n"Default";
	BurstForce.Forces.Add(Force);	
	BurstForce.Feature = OptionalFeature;
	BurstForce.TargetFacingDirection = FaceRotation.Vector().ConstrainToPlane(WorldUp).GetSafeNormal();
	BurstForce.FadeOutTimer.Start(1.f, 1.f);
	BurstComp.AddBurstForce(BurstForce, EHazeBurstForceAddType::TreatAsNew);
}

UFUNCTION(BlueprintCallable)
void AddBurstForceWallImpact(AHazeActor Actor, FVector WallImpactNormalDirection)
{
	if(Actor == nullptr)
		return;

	UHazeBaseMovementComponent MoveComp = UHazeBaseMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

	UHazeBurstForceComponent BurstComp = UHazeBurstForceComponent::GetOrCreate(Actor);
	FHazeBurstAddForceData WallCounterForce;

	const float CollisionSpeed = MoveComp.GetVelocity().Size2D(MoveComp.WorldUp);
	FVector ImpactForce = WallImpactNormalDirection * CollisionSpeed;	
	const float ImpactSize = FMath::Clamp(ImpactForce.Size() * 100.f, 250.f, 1000.f) ;
	ImpactForce = ImpactForce.GetSafeNormal() * ImpactSize;
	ImpactForce -= MoveComp.GetGravity() * (1.f/30.f);
	ImpactForce += MoveComp.WorldUp * 400.f;
	
	WallCounterForce.Forces.Add(ImpactForce);
	WallCounterForce.ForceType = MoveComp.IsGrounded() ? n"WallImpactGrounded" : n"WallImpactAir";
	GetBurstForceFeaturePart(UHazeCharacterSkeletalMeshComponent::Get(Actor), WallCounterForce.ForceType, WallCounterForce.Feature);
	WallCounterForce.TargetFacingDirection = (-ImpactForce).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
	WallCounterForce.FadeOutTimer.Start(0.5f, 1.f);

	BurstComp.AddBurstForce(WallCounterForce, EHazeBurstForceAddType::TreatAsNew);
}