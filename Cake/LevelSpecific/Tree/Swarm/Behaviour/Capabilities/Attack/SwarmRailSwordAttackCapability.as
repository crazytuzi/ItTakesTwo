
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmAttackPerformed;
import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmAttackStarted;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.Phase3RailSwordComponent;
import Cake.Weapons.Match.MatchWeaponStatics;
import Cake.LevelSpecific.Tree.Queen.QueenActor;
import Cake.Weapons.Sap.SapWeaponStatics;

class USwarmRailSwordAttackCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Attack;
	UHazeSplineComponent Spline = nullptr;
	float TimeSincePlayerGrinded = 0.f;
	bool bReachedEnd = false;

	FHazeSplineSystemPosition SwarmSplinePosData;
	bool bPlayedEnterAnim = false;

	// which direction the swarm should go in
	float Direction = 1.f;

	UPhase3RailSwordComponent ManagedSwarmComp;


	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		// Telegraph init will set this
		if(MoveComp.HasSplineToFollow() == false)
			return EHazeNetworkActivation::DontActivate;

		// return EHazeNetworkActivation::ActivateLocal;
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// return EHazeNetworkDeactivation::DeactivateLocal;

		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MoveComp.HasSplineToFollow() == false)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		// if(HasReachedEndOfSpline_Swarm())
		// 	return EHazeNetworkDeactivation::DeactivateLocal;

		//if(HasReachedEndOfSpline_Player())
			//return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		// The point we want to query needs to be outside of the railSpline "circle"
		const FVector ArenaMidPos = MoveComp.ArenaMiddleActor.GetActorLocation();
		FVector QueenToSwarm = SwarmActor.GetActorLocation() - ArenaMidPos;
		QueenToSwarm = QueenToSwarm.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

		// const FVector SplineCOM = Spline.CalcCenterOfSpline();
		// const FVector SplineCOM = Spline.CalcCenterOfSplineSystemPosition();
		const FVector SplineCOM = MoveComp.ArenaMiddleActor.GetActorLocation();

		const FVector PointToQuery = SplineCOM + QueenToSwarm * 10000.f;
		OutParams.AddVector(n"PointToQuery", PointToQuery);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ManagedSwarmComp = UPhase3RailSwordComponent::Get(Owner);

		// Direction *= -1.f;

		SwarmActor.PlaySwarmAnimation(
			Settings.RailSword.TelegraphInitial.AnimSettingsDataAssetEnter,
			this,
			//Settings.RailSword.TelegraphInitial.TelegraphingTime
			0.f
		);

		BehaviourComp.NotifyStateChanged();

		VictimComp.OverrideClosestPlayer(VictimComp.PlayerVictim, this);

		Spline = MoveComp.GetSplineToFollow();

		const FVector PointToQuery = ActivationParams.GetVector(n"PointToQuery");
		SwarmSplinePosData  = Spline.FindSystemPositionClosestToWorldLocation(PointToQuery);

//		System::DrawDebugSphere(SwarmSplinePosData.GetWorldLocation(), 500.f, 32, GetDebugColoring(), 15.f);

		const float LengthThatWillGetUsToTheEnd = 20000.f;		// Dont do BIG_NUMBER here!
		SwarmSplinePosData.Move(LengthThatWillGetUsToTheEnd);
		SwarmSplinePosData.Reverse();
		bReachedEnd = false;

		TimeUntilMovementStarts = 3.f;
		if(!HasControl())
		{
			// The sword will stay at the location for 3 seconds...
			// it will be traveling towards the players once it starts moving.
			// Having it be (potentially) ahead of the control side would be better than having it 
			// lag behind because the remote players will be lagging behind as well but in opposite direction
			const float HalfPing = Network::GetPingRoundtripSeconds() * 0.5f;
			TimeUntilMovementStarts = FMath::Max(TimeUntilMovementStarts - HalfPing, 0.f);
//			Print("TimeUntilMovementStarts: " + TimeUntilMovementStarts);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);

		Spline = nullptr;
		TimeSincePlayerGrinded = 0.f;

		PrioritizeState(ESwarmBehaviourState::TelegraphDefence);
		bPlayedEnterAnim = false;

		ClearPOI();
	}

	float TimeUntilMovementStarts = 3.f;

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		UpdateGrindingDistanceToPlayers();

		// Start moving along the spline after 'telegraphing'
		const float CurrentStateDuration = BehaviourComp.GetStateDuration();
		if (CurrentStateDuration >= TimeUntilMovementStarts && bPlayedEnterAnim == false)
		{
			SwarmActor.PlaySwarmAnimation(
				Settings.RailSword.Attack.AnimSettingsDataAsset,
				this,
				3.f
			);
			bPlayedEnterAnim = true;
		}

		float AttackSpeed = Settings.RailSword.Attack.AttackSpeed;
		if(bPlayedEnterAnim == false)
			AttackSpeed = 0.f;

		bReachedEnd = !SwarmSplinePosData.Move(DeltaSeconds * AttackSpeed * Direction);

		const FVector SplineLoc = SwarmSplinePosData.GetWorldLocation();
		const FQuat SplineRot = SwarmSplinePosData.GetWorldOrientation();
		const FVector ArenaMidPos = MoveComp.ArenaMiddleActor.GetActorLocation();
  		const FQuat QueenToRailQuat = Math::MakeQuatFromX(SplineLoc - ArenaMidPos);
		const FQuat SwarmToRailQuat = MoveComp.GetFacingRotationTowardsLocation(SplineLoc);
 		const FVector AlignOffset = QueenToRailQuat.RotateVector(SkelMeshComp.GetAlignBoneLocalLocation());
		const FTransform DesiredTransform = FTransform(SwarmToRailQuat, SplineLoc - AlignOffset);

//		System::DrawDebugSphere(DesiredTransform.GetLocation(), LineColor = GetDebugColoring(), Duration = 0.f);
//		PrintToScreenScaled("Distance along Spline: " + SwarmSplinePosData.DistanceAlongSpline, 0.f, GetDebugColoring(), Scale = 2.f);
		//  PrintToScreen("Ping: " + Network::GetPingRoundtripSeconds());

		MoveComp.SpringToTargetLocation (
			DesiredTransform.GetLocation(),
			Settings.RailSword.Attack.SpringToLocationStiffness,
			Settings.RailSword.Attack.SpringToLocationDamping,
			DeltaSeconds
		);

		MoveComp.InterpolateToTargetRotation(
			DesiredTransform.GetRotation(),
			3.f, 
			false,
			DeltaSeconds	
		);

		const UHazeSplineFollowComponent SplineFollowComp  = VictimComp.GetSplineFollowComp();
		if(SplineFollowComp.HasActiveSpline())
			TimeSincePlayerGrinded = 0.f;
		else
			TimeSincePlayerGrinded += DeltaSeconds;

		UpdatePointOfInterests();
		UpdateShakeAndRumble();

		BehaviourComp.FinalizeBehaviour();
 	}

	void UpdateShakeAndRumble()
	{
		// noise [0, 1] range
//		const float FramePerlin = (1.f + FMath::PerlinNoise1D(Time::GetGameTimeSeconds()))* 0.5f;
		// float LargeMotor = 0.8f + FramePerlin * 0.2f;
		// float SmallMotor = 0.8f + FramePerlin * 0.2f;
		// LargeMotor *= 0.6f;
		// SmallMotor *= 0.6f;

		float LargeMotor = 0.3f;
		float SmallMotor = 0.3f;

		const float CloseEnoughThreshold = 6500.f;

		for (AHazePlayerCharacter IterPlayer : Game::Players)
		{
			UUserGrindComponent GrindComp = UUserGrindComponent::Get(IterPlayer);

			if (GrindComp == nullptr)
				continue;

			if(!GrindComp.IsGrindingActive())
				continue;

			const float Dist = GrindingDistanceToPlayer[IterPlayer];

			if(Dist > CloseEnoughThreshold)
				continue;

			ensure(Dist >= 0.f);

			float Scale = 1.f - FMath::Min(Dist / CloseEnoughThreshold, 1.f);
			Scale = FMath::SmoothStep(0.f, 1.f, Scale);

			// PrintToScreen(SwarmActor.GetName() + " Scale to " + IterPlayer.GetName() + " : " + Scale);

			IterPlayer.SetFrameForceFeedback(LargeMotor * Scale, SmallMotor * Scale);
		}
	}

	void ClearPOI()
	{
		for (auto InPlayer : Game::Players)
		{
			InPlayer.ClearPointOfInterestByInstigator(this);
		}
	}

	private TPerPlayer<float> GrindingDistanceToPlayer;

	void UpdateGrindingDistanceToPlayers()
	{
		for (AHazePlayerCharacter IterPlayer : Game::Players)
		{
			GrindingDistanceToPlayer[IterPlayer] = BIG_NUMBER;

			UUserGrindComponent GrindComp = UUserGrindComponent::Get(IterPlayer);

			if (GrindComp == nullptr)
				continue;

			if(!GrindComp.IsGrindingActive())
				continue;

			if(GrindComp.FollowComp == nullptr)
				continue;

			if(!GrindComp.FollowComp.HasActiveSpline())
				continue;

			GrindingDistanceToPlayer[IterPlayer] = SwarmSplinePosData.DistancePositive(GrindComp.SplinePosition);
		}
	}

	bool IsWithinPOIDistance(AHazePlayerCharacter InPlayer) const
	{
		const FVector SwarmAlignSocketPos = SwarmActor.SkelMeshComp.GetSocketLocation(n"Align");
		const FVector PlayerToSwarm = SwarmAlignSocketPos - InPlayer.ActorLocation;
		const float DistanceToSwordCollisionSQ = PlayerToSwarm.SizeSquared();
		const float MinDistSQ = FMath::Square(4000.f);
		const bool bWithinDistance = DistanceToSwordCollisionSQ < MinDistSQ;

		// bPlayerHeadingTowardsSwarm && bThresholdCrossed && bSwarmHeadingTowardsPlayer
		if(bWithinDistance 
		&&	SwarmActor.MovementComp.TranslationVelocity.DotProduct(PlayerToSwarm) < 0 		
		&&	InPlayer.ActorVelocity.DotProduct(PlayerToSwarm) > 0)
		{
			return true;
		}

		return false;
	}

	void UpdatePointOfInterests()
	{
		for (AHazePlayerCharacter IterPlayer : Game::Players)
			UpdatePointOfInterestForPlayer(IterPlayer);
	}

	void UpdatePointOfInterestForPlayer(AHazePlayerCharacter InPlayer)
	{
		if (!IsWithinPOIDistance(InPlayer) || IsHookWithinView(InPlayer))
		{
			if (IsPOIActive(InPlayer))
			{
				InPlayer.ClearPointOfInterestByInstigator(this);
			}

			return;
		}

//		System::DrawDebugArrow(InPlayer.GetActorLocation(), SwarmActor.SkelMeshComp.GetSocketLocation(n"Align"));

		if(IsPOIActive(InPlayer))
			return;

		ApplyPOI(InPlayer);
	}
	
	void ApplyPOI(AHazePlayerCharacter InPlayer)
	{

		FHazePointOfInterest POI = FHazePointOfInterest();
		POI.FocusTarget = FHazeFocusTarget();
		POI.FocusTarget.Actor = SwarmActor;

		const bool bAiming = InPlayer.IsMay() ? IsAimingWithMatchWeapon() : IsAimingWithSapWeapon();

		if(bAiming)
		{
			POI.FocusTarget.Component = SwarmActor.SkelMeshComp;
			POI.FocusTarget.Socket = n"Align";
		}
		else
		{
			POI.FocusTarget.ViewOffset = FVector::RightVector * -200;
		}
		
		POI.Clamps.ClampYawLeft = 90.f;
		POI.Clamps.ClampYawRight = 90.f;
		POI.Blend.BlendTime = 1.f;

		// System::DrawDebugLine(SwarmAlignSocketPos, InPlayer.ActorLocation, FLinearColor::DPink, 0.f, 10.f);

		InPlayer.ClearSettingsByInstigator(this);
		InPlayer.ApplyClampedPointOfInterest(POI, this, EHazeCameraPriority::Script);
		// InPlayer.ApplyInputAssistPointOfInterest(POI, this, EHazeCameraPriority::Script);
	}


	bool IsHookWithinView(AHazePlayerCharacter InPlayer) const
	{
		const FVector2D WithinFraction = FVector2D(0.3, 0.7f);
		const AQueenActor Queen = Cast<AQueenActor>(SwarmActor.MovementComp.ArenaMiddleActor);
		return SceneView::IsInView(InPlayer, Queen.Mesh.GetSocketLocation(n"Base"), WithinFraction, WithinFraction);
	}

	bool IsPOIActive(AHazePlayerCharacter InPlayer)
	{
		auto CameraUser = UHazeActiveCameraUserComponent::Get(InPlayer);
		if(CameraUser.GetPointOfInterest().PointOfInterest.FocusTarget.Actor == SwarmActor)
			return true;

		return false;
	}

	bool HasReachedEndOfSpline_Swarm() const
	{
		return bReachedEnd;
	}

	bool HasReachedEndOfSpline_Player() const
	{
		UHazeSplineFollowComponent SplineFollowComp  = VictimComp.GetSplineFollowComp();
		if(SplineFollowComp.HasActiveSpline())
			return false;

		return TimeSincePlayerGrinded > 1.f;
	}

	FLinearColor GetDebugColoring() const
	{
		FLinearColor DebugColor = FLinearColor::Yellow;
		if(ManagedSwarmComp.AssignedIndex == 0)
			DebugColor = FLinearColor::Red;
		else if(ManagedSwarmComp.AssignedIndex == 1)
			DebugColor = FLinearColor::LucBlue;
		else if(ManagedSwarmComp.AssignedIndex == 2)
			DebugColor = FLinearColor::Green;
		return DebugColor;
	}

}



