import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneBodyAlignmentCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 2;

	AMurderMicrophone Snake;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Snake.bEnableBodyAlignment)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float DistanceToCore = FMath::Max((Snake.ActorLocation.DistSquared2D(Snake.HeadOffset.WorldLocation)), 1.0f);
		float CoreCordOffsetFraction = FMath::Max(DistanceToCore / Snake.StartingDistanceToCore, 1.0f);
		FVector DirectionToCore = (Snake.WeakPoint.WorldLocation - Snake.HeadOffset.WorldLocation).GetSafeNormal2D();
		const float DirDot = DirectionToCore.DotProduct(Snake.HeadOffset.ForwardVector.GetSafeNormal2D());
		Snake.CordBottomOffset = (DirectionToCore * -1.0f) * (10.0f * CoreCordOffsetFraction);
		float OffsetValue = (FMath::Max(FMath::Sqrt(DistanceToCore), Snake.BodyAlignmentLength));

		float DotTest = FMath::Sign(Snake.ActorRightVector.DotProduct(Snake.HeadOffset.ForwardVector.GetSafeNormal2D()));
		float DirDotAbs = FMath::Abs(DirDot);

		if(DotTest > 0.0f && Snake.Local_CordControlPointBottom.Y > 0.0f)
			OffsetValue -= Snake.Local_CordControlPointBottom.Y;
		else if(DotTest < 0.0f && Snake.Local_CordControlPointBottom.Y > 0.0f)
			OffsetValue += Snake.Local_CordControlPointBottom.Y;

		OffsetValue *= -1.0f;

		float TargetControlPointOffset = 0.0f;

		if(DirDotAbs > 0.4f)
		{
			TargetControlPointOffset = (OffsetValue * DirDotAbs) * DotTest;
		}
		
		/*
		PrintToScreen("DirDot " + DirDot);
		PrintToScreen("OffsetValue * DirDotAbs " + OffsetValue * DirDotAbs);
		PrintToScreen("DistanceToCore " + FMath::Sqrt(DistanceToCore));
		PrintToScreen("Local_CordControlPointBottom " + Local_CordControlPointBottom);
		*/

		Snake.ControlPointTopOffset = FMath::FInterpTo(Snake.ControlPointTopOffset, TargetControlPointOffset, DeltaTime, 1.6f);
		//System::DrawDebugSphere(SplineControlPointBottom);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Snake.bEnableBodyAlignment)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}
