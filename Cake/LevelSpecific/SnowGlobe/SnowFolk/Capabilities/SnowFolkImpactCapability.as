import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkSplineFollower;

enum ESnowFolkImpactState
{
	None,
	Hit,
	Down,
	Recover,
	Grace
}

class USnowFolkImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowFolkImpactCapability");
	default CapabilityDebugCategory = n"SnowFolkImpactCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASnowfolkSplineFollower SnowFolk;
	UHazeCrumbComponent CrumbComp;
	USnowballFightResponseComponent SnowballResponseComp;
	USnowFolkFauxCollisionComponent FauxCollisionComp;

	ESnowFolkImpactState ImpactState = ESnowFolkImpactState::None;
	float ImpactTimer = 0.f;
	float GraceDuration = 0.3f;

	private bool bImpactByTackle = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& SetupParams)
	{
		SnowFolk = Cast<ASnowfolkSplineFollower>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(SnowFolk);
		SnowballResponseComp = USnowballFightResponseComponent::Get(SnowFolk);
		FauxCollisionComp = USnowFolkFauxCollisionComponent::Get(SnowFolk);

		FauxCollisionComp.OnPlayerForwardImpact.AddUFunction(this, n"HandlePlayerForwardImpact");
		SnowballResponseComp.OnSnowballHit.AddUFunction(this, n"HandleSnowballHit");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SnowFolk.bCanBeKnocked)
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(n"WasImpacted"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SnowFolk.bCanBeKnocked)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

		if (ImpactState == ESnowFolkImpactState::None)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SnowFolk.PatrolAudioComp.HandleInteruption();

		if(bImpactByTackle)
			SnowFolk.SnowfolkHazeAkComp.HazePostEvent(SnowFolk.PatrolAudioComp.OnTackledEvent);
		else
			SnowFolk.SnowfolkHazeAkComp.HazePostEvent(SnowFolk.ProjectileHitAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams& DeactivationParams)
	{
		ImpactTimer = 0.f;
		ImpactState = ESnowFolkImpactState::None;
		SnowFolk.bIsHit = false;
		SnowFolk.bIsDown = false;
		SnowFolk.bIsRecovering = false;

		SnowFolk.PatrolAudioComp.FinishInteruption();
		bImpactByTackle = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsActioning(n"WasImpacted"))
		{
			if (ImpactState == ESnowFolkImpactState::None)
			{
				ChangeState(ESnowFolkImpactState::Hit);
			}
			else if (ImpactState == ESnowFolkImpactState::Hit && SnowFolk.MovementComp.bIsSkating)
			{
				ChangeState(ESnowFolkImpactState::Down);
			}

			// Consume action state, seems it's active for two ticks otherwise
			SnowFolk.SetCapabilityActionState(n"WasImpacted", EHazeActionState::Inactive);
		}

		if (ImpactTimer > 0.f)
		{
			ImpactTimer -= DeltaTime;
			return;
		}

		switch (ImpactState)
		{
		case ESnowFolkImpactState::Hit:
		case ESnowFolkImpactState::Recover:
			ChangeState(ESnowFolkImpactState::Grace);
			break;

		case ESnowFolkImpactState::Grace:
			ChangeState(ESnowFolkImpactState::None);
			break;

		case ESnowFolkImpactState::Down:
			ChangeState(ESnowFolkImpactState::Recover);
			break;
		}
	}

	void ChangeState(ESnowFolkImpactState NewState)
	{
		SnowFolk.bIsHit = (NewState == ESnowFolkImpactState::Hit);
		SnowFolk.bIsDown = (NewState == ESnowFolkImpactState::Down);
		SnowFolk.bIsRecovering = (NewState == ESnowFolkImpactState::Recover);

		switch (NewState)
		{
		case ESnowFolkImpactState::None:
			ImpactTimer = 0.f;
			break;

		case ESnowFolkImpactState::Hit:
			ImpactTimer = SnowFolk.ImpactDuration;
			if (!SnowFolk.MovementComp.bIsSkating)
				SnowFolk.SkeletalMeshComponent.SetAnimBoolParam(n"PlayerDashed", true);
			break;

		case ESnowFolkImpactState::Down:
			ImpactTimer = SnowFolk.FallDuration;
			break;

		case ESnowFolkImpactState::Recover:
			ImpactTimer = SnowFolk.RecoveryDuration;
			break;
			
		case ESnowFolkImpactState::Grace:
			ImpactTimer = GraceDuration;
			break;
		}

		// Print("" + int(ImpactState) + " > " + int(NewState), 5.f);

		ImpactState = NewState;
	}

	bool WasImpactFromLeft(FVector ImpactNormal)
	{
		// Check back in order to invert the direction of left/right
		bool bImpactFromBack = SnowFolk.ActorForwardVector.DotProduct(ImpactNormal) < 0.f;
		bool bImpactFromLeft = SnowFolk.ActorRightVector.DotProduct(ImpactNormal) < 0.f;

		if (!bImpactFromBack)
			bImpactFromLeft = !bImpactFromLeft;

		return bImpactFromLeft;
	}
	
	UFUNCTION()
	void HandleSnowballHit(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(ProjectileOwner);

		if (Player == nullptr)
			return;

		SnowFolk.bHitFromLeft = WasImpactFromLeft(HitVelocity.GetSafeNormal());
		SnowFolk.SetCapabilityActionState(n"WasImpacted", EHazeActionState::Active);
	}

	UFUNCTION()
	void HandlePlayerForwardImpact(AHazePlayerCharacter Player, const FVector& Normal, bool bDashing)
	{
		if (!SnowFolk.bCanBeKnocked)
			return;

		// Impact if player is dashing or if the velocity is high enough while skating
		if (SnowFolk.MovementComp.bIsSkating)
		{
			if (Player.MovementComponent.Velocity.Size() <= SnowFolk.ImpactVelocityThreshold)
				return;
		}
		else
		{
			if (!bDashing)
				return;
		}

		SnowFolk.bHitFromLeft = WasImpactFromLeft(Normal);
		SnowFolk.SetCapabilityActionState(n"WasImpacted", EHazeActionState::Active);

		if (SnowFolk.ImpactForceFeedback != nullptr)
			Player.PlayForceFeedback(SnowFolk.ImpactForceFeedback, false, false, n"SnowFolkImpact");

		bImpactByTackle = true;
	}
}