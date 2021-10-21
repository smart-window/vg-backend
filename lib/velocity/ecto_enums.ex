import EctoEnum

defenum(TrainingStatusEnum, :training_status, [:not_started, :in_progress, :completed])

defenum(FormFieldTypeEnum, :form_field_type, [
  :date,
  :number,
  :phone,
  :private,
  :select,
  :text,
  :boolean,
  :address
])

defenum(RoleAssignmentTypeEnum, :role_assignment_type, [
  :global,
  :external
])

defenum(PTODecisionEnum, :pto_decision, [
  :approve,
  :reject,
  :return,
  :modify
])

defenum(PTOSlotEnum, :pto_slot, [
  :all_day,
  :half_day,
  :morning,
  :afternoon,
  :time
])

defenum(DocumentStatusEnum, :document_status_type, [
  :not_started,
  :completed
])

defenum(DocumentFileTypeEnum, :document_file_type, [
  :document,
  :image,
  :sheet,
  :contract
])

defenum(DocumentTemplateFileTypeEnum, :document_template_file_type, [
  :document,
  :image,
  :sheet,
  :contract
])

defenum(EmploymentEndReasonEnum, :employment_end_reason, [
  :lost,
  :terminated,
  :contract_change,
  :partner_change,
  :client_change
])

defenum(TaskCommentVisibilityType, :task_comment_visibility_type, [
  :public,
  :internal_only
])

defenum(ClientSegmentTypeEnum, :client_segment_type, [
  :standard_peo,
  :expansion,
  :partnership,
  :strategic
])

defenum(PaymentTypeEnum, :payment_type, [
  :ach,
  :wire
])

defenum(PartnerTypeEnum, :partner_type, [
  :in_country_partner,
  :managed_service_provider
])

defenum(PartnerServiceTypeEnum, :partner_service_type, [
  :peo_expatriate,
  :peo_local_national,
  :immigration,
  :ess,
  :recruitment
])

defenum(DocumentTemplateCategoryTypeEnum, :document_template_category_type, [
  :client,
  :employee,
  :all
])

defenum(USMonthEnumEnum, :us_month_enum, [
  :january,
  :february,
  :march,
  :april,
  :may,
  :june,
  :july,
  :august,
  :september,
  :october,
  :november,
  :december
])

defenum(EmploymentTypeEnum, :employment_type, [
  :indefinite,
  :three_month_fixed,
  :three_year_fixed_term,
  :twelve_fixed_auto_renewal,
  :eighteen_month_fixed,
  :contractor,
  :fixed_term_back_to_back,
  :fixed_term,
  :not_applicable,
  :unknown
])

defenum(EmploymentStatusEnum, :employment_status, [
  :full_time,
  :part_time,
  :contractor
])

defenum(ProbationaryPeriodTermEnum, :probationary_period_term_type, [
  :days,
  :months
])

defenum(TerminationReasonEnum, :termination_reason_enum, [
  :client_offboarded_from_velocity_global,
  :company_strategy,
  :country_regulation_or_restriction_change,
  :customer_left_for_a_competitor,
  :employee_resignation,
  :entity_transfer,
  :fixed_term_contract_ends,
  :immigration,
  :probation_period_ends,
  :termination_with_cause,
  :velocity_global_ended_relationship_with_client
])

defenum(TerminationSubReasonEnum, :termination_sub_reason_enum, [
  :unhappy_with_peo_model,
  :unhappy_with_velocity_global_service,
  :change_in_company_strategy,
  :client_acquired_by_another_company,
  :other_see_comments,
  :budget_cuts_in_market,
  :customer_dissolved_operations_in_market,
  :aug,
  :price,
  :service_issues,
  :rejected_move_to_velocity_global_entity,
  :unknown,
  :accepted_new_opportunity,
  :compensation_unhappy_with_role,
  :family_reasons,
  :relocation,
  :retirement,
  :service_issues_with_velocity_global,
  :mta,
  :redundancy_of_position,
  :move_to_velocity_global_entity,
  :velocity_global_moved_ees_to_new_icp_in_country,
  :ee_relocates_to_a_new_country_changes_icp,
  :moved_ee_to_clients_entity,
  :ee_did_not_renew_contract,
  :client_opted_not_to_renew_contract,
  :visa_denial_from_onset,
  :visa_renewal_denied,
  :client_refused_to_pay_for_immigration,
  :country_regulations_change,
  :american_legislation_changes,
  :unworkable_processing_time,
  :client_opted_not_to_move_forward_with_ee,
  :probation_period_extension_rejected_by_ee,
  :bad_actor_stealing_drinking_misconduct,
  :poor_performance,
  :attendance,
  :client_did_not_adhere_to_velocity_global_values,
  :funding_issues_ar
])

defenum(EmailRecipientTypeEnum, :email_recipient_type, [
  :from,
  :to,
  :cc,
  :bcc
])

defenum(OperationalTierTypeEnum, :operational_tier, [
  :standard,
  :strategic
])
