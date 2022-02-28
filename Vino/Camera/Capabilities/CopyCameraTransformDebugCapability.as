import Vino.Camera.CameraStatics;

#if TEST
class UCopyCameraTransformDebugCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default TickGroup = ECapabilityTickGroups::LastDemotable; // AFter camera view is finalized
    default CapabilityDebugCategory = CapabilityTags::Debug;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if (!IsActioning(n"DebugCopyCameraTransform"))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CopyCameraTransform();
		ConsumeAction(n"DebugCopyCameraTransform");
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"CopyCameraTransform", "CopyCameraTransform");
			Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"Camera");
		}
	}

	UFUNCTION()
	void CopyCameraTransform()
	{
		CopyCameraTransformToClipboard(Cast<AHazePlayerCharacter>(Owner));
	}

}	
#endif