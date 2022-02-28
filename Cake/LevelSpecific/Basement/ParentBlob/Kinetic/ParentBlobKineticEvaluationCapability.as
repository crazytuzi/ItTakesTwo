import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticComponent;
import Peanuts.Aiming.AutoAimStatics;


class UParentBlobKineticEvaluationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityTags.Add(n"KineticTargeting");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AParentBlob ParentBlob;
	UParentBlobKineticComponent KineticComponent;
	UParentBlobKineticInteractionComponent BestFoundInteraction;
	TArray<UParentBlobKineticInteractionComponent> PlayerTargetInteraction;
	default PlayerTargetInteraction.SetNum(2);

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
		KineticComponent = UParentBlobKineticComponent::Get(ParentBlob);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ParentBlob == nullptr)
			return EHazeNetworkActivation::DontActivate;

		auto KineticTeam = HazeAIBlueprintHelper::GetTeam(n"BlobKinetic");
		if(KineticTeam == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(KineticTeam.Members.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ParentBlob == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		auto KineticTeam = HazeAIBlueprintHelper::GetTeam(n"BlobKinetic");
		if(KineticTeam == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		if(KineticTeam.Members.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		if(BestFoundInteraction != nullptr && BestFoundInteraction.bHasBeenCompleted)
			BestFoundInteraction = nullptr;
		
		for(int i = 0; i < 2; ++i)
		{
			if(PlayerTargetInteraction[i] != nullptr && PlayerTargetInteraction[i] .bHasBeenCompleted)
				PlayerTargetInteraction[i] = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			FParentBlobKineticPlayerInputData& InputData = KineticComponent.PlayerInputData[int(Player.Player)];
			InputData.TargetedInteraction = nullptr;

			auto Visualizer = KineticComponent.GetKineticVisualizer(Player);
			if(Visualizer != nullptr)
				Visualizer.SetStatus(EKineticInputVisualizerStatus::Inactive);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			auto KineticTeam = Cast<UParentBlobKineticTeam>(HazeAIBlueprintHelper::GetTeam(n"BlobKinetic"));

			UParentBlobKineticInteractionComponent BestInteration = nullptr;
			float BestScore = -1;
			TSet<AHazeActor> KineticTeamMemebers = KineticTeam.GetMembers();
			for (AHazeActor KineticActor : KineticTeamMemebers)
			{
				if(KineticActor == nullptr)
					continue;

				const FVector DirToPoint = (KineticActor.GetActorLocation() - ParentBlob.GetActorLocation()).GetSafeNormal();
				const float DirAlpha = Game::GetMay().GetControlRotation().ForwardVector.DotProduct(DirToPoint);
				if(DirAlpha < 0)
					continue;

				auto Interaction = UParentBlobKineticInteractionComponent::Get(KineticActor);
				if(Interaction.bHasBeenCompleted)
					continue;

				const float DistSq = KineticActor.GetActorLocation().DistSquared(ParentBlob.GetActorLocation());
				const float DistAlpha = FMath::Min(DistSq / FMath::Square(10000.f), 1.f);

				float VisibilityDistanceScore = 0;
				if(Interaction.bUseVisibilityDistance)
				{
					if(DistSq > FMath::Square(Interaction.VisibilityDistance))
						continue;
			
					const float MaxDistanceScore = DistSq > FMath::Square(Interaction.VisibilityDistance) ? 10.f : 50.f;
					VisibilityDistanceScore = FMath::Lerp(0.f, MaxDistanceScore, DistAlpha);
				}
				else if(DistSq > FMath::Square(Interaction.ActivationDistance))
					continue;
					
				const float MaxDistanceScore = DistSq > FMath::Square(Interaction.ActivationDistance) ? 0.f : 50.f;
				const float InRangeDistanceScore = FMath::Lerp(0.f, MaxDistanceScore, DistAlpha);
		
				const float AngleScore = FMath::Lerp(0.f, 30.f, DirAlpha);

				const float TotalScore = VisibilityDistanceScore + InRangeDistanceScore + AngleScore;
				if(TotalScore > BestScore)
				{
					BestScore = TotalScore;
					BestInteration = Interaction;
				}
			}

			if(BestFoundInteraction != BestInteration)
				NetSetMostValidInteraction(BestInteration);
		}
		
		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			FParentBlobKineticPlayerInputData& InputData = KineticComponent.PlayerInputData[int(Player.Player)];
		
			const FTransform AttachTransform = KineticComponent.GetVisualizerAttachmentTransform(Player);
			auto Visualizer = KineticComponent.GetKineticVisualizer(Player);

			if(Player.HasControl())
			{
				bool bInteractionIsValid = false;
				if(BestFoundInteraction != nullptr 
					&& !BestFoundInteraction.bHasBeenCompleted)
				{	
					if(InputData.bSteeringIsToFindInteraction)
						bInteractionIsValid = InputData.bHasSteeringInput;
					else
						bInteractionIsValid = true;

					FVector InputDirection = FRotator(0.f, InputData.InputAngle, 0.f).Vector();
					InputDirection = ParentBlob.GetActorTransform().TransformVector(InputDirection);

					// We have to aim at the most valid interaction to activate it
					const FVector DirToInteraction = BestFoundInteraction.GetWorldLocation() - ParentBlob.GetActorLocation();	
					if(DirToInteraction.Size() > BestFoundInteraction.ActivationDistance)
						bInteractionIsValid = false;
					else if(InputData.bSteeringIsToFindInteraction && DirToInteraction.GetSafeNormal().DotProduct(InputDirection) < 0.775f)
						bInteractionIsValid = false;
				}

				if(bInteractionIsValid && BestFoundInteraction != PlayerTargetInteraction[int(Player.Player)])
					NetSetPlayerTargetedInteraction(Player, BestFoundInteraction);
				else if(!bInteractionIsValid && PlayerTargetInteraction[int(Player.Player)] != nullptr)
					NetSetPlayerTargetedInteraction(Player, nullptr);
			}

			InputData.TargetedInteraction = PlayerTargetInteraction[int(Player.Player)];
			if(InputData.TargetedInteraction != nullptr)
			{	
				if(InputData.bSteeringIsToFindInteraction)
				{
					if(InputData.bIsHolding)
						Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithTargetAndInput);
					else
						Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithTarget);
				}
				else
				{
					if(InputData.bHasSteeringInput)
					{
						if(InputData.InputIsValidToRequiredAngle)
						{
							if(InputData.bIsHolding)
								Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithTargetAndInputAndValidDirection);
							else
								Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithTargetAndValidDirection);
						}
						else
						{
							if(InputData.bIsHolding)
								Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithTargetAndInput);
							else
								Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithTarget);
						}
					}
					else
					{
						if(InputData.bIsHolding)
							Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithTargetAndInput);
						else
							Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithTarget);
					}
				}
	
				FVector TargetLocation = InputData.TargetedInteraction.GetInteractionTransform(Player.Player).GetLocation();
				TargetLocation = FMath::VInterpTo(Visualizer.GetActorLocation(), TargetLocation, DeltaTime, 7.5f);
				Visualizer.SetActorLocation(TargetLocation);
			}
			else
			{
				FVector TargetLocation = FMath::VInterpTo(Visualizer.GetActorLocation(), AttachTransform.GetLocation(), DeltaTime, 4.f);
				Visualizer.SetActorLocation(TargetLocation);
				if(InputData.bSteeringIsToFindInteraction && InputData.bHasSteeringInput)
				{
					if(InputData.bIsHolding)
						Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithNoTargetAndInput);
					else
						Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithNoTarget);
				}
				else
				{
					const float Distance =  AttachTransform.GetLocation().Distance(Visualizer.GetActorLocation());	
					if(Distance < 50)
						Visualizer.SetStatus(EKineticInputVisualizerStatus::Inactive);
					else
						Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithNoTarget);
				}	
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetMostValidInteraction(UParentBlobKineticInteractionComponent NewInteraction)
	{
		BestFoundInteraction = NewInteraction;
	}

	UFUNCTION(NetFunction)
	void NetSetPlayerTargetedInteraction(AHazePlayerCharacter Player, UParentBlobKineticInteractionComponent NewInteraction)
	{
		PlayerTargetInteraction[int(Player.Player)] = NewInteraction;
	}
}