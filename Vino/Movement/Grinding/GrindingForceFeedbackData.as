class UGrindingForceFeedbackData : UDataAsset
{
	/* Proximity */ 
	UPROPERTY(Category = "Enter|Proximity")
    UForceFeedbackEffect GrindProximityLandRumble;
	

	/* Grapple */ 
	UPROPERTY(Category = "Enter|Grapple|Attach")
    UForceFeedbackEffect GrappleAttachRumble;

	UPROPERTY(Category = "Enter|Grapple")
    UForceFeedbackEffect GrappleConstantRumble;

	UPROPERTY(Category = "Enter|Grapple|Land")
    UForceFeedbackEffect GrappleLandRumble;


	/* Transfer */ 
	UPROPERTY(Category = "Enter|Transfer")
    UForceFeedbackEffect TransferJumpRumble;

	UPROPERTY(Category = "Enter|Transfer")
    UForceFeedbackEffect TransferLandRumble;


	UPROPERTY(Category = "Grind")
    UForceFeedbackEffect GrindRumble;

	UPROPERTY(Category = "Grind|Jump")
    UForceFeedbackEffect GrindJumpRumble;

	UPROPERTY(Category = "Grind|Dash")
    UForceFeedbackEffect GrindDashRumble;
}
