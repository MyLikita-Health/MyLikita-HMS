-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jan 10, 2026 at 03:06 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `prime`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `addExpensesRemarks` (IN `in_remarks_id` VARCHAR(20), IN `in_request_no` VARCHAR(50), IN `in_remarks` VARCHAR(100), IN `in_remarks_by` VARCHAR(50), IN `in_date` VARCHAR(20), IN `in_general_remarks` VARCHAR(100), IN `in_facilityId` VARCHAR(50))  NO SQL INSERT INTO remarks(remarks_id,request_no,remarks,remarks_by,date,general_remarks,facilityId)
VALUES(in_remarks_id,in_request_no,in_remarks,in_remarks_by,in_date,in_general_remarks,in_facilityId)$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addInsuranceType` (IN `in_insurance_name` VARCHAR(30), IN `in_percentage` INT, IN `in_packages` VARCHAR(15))   BEGIN
    INSERT INTO insuranceTable( insurance_name, percentage, packages) 
    VALUE (in_insurance_name, in_percentage, in_packages);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addNewExpenses` (IN `in_date` VARCHAR(20), IN `in_month` VARCHAR(20), IN `in_branch_name` VARCHAR(50), IN `in_request_no` VARCHAR(20), IN `in_particulars` VARCHAR(50), IN `in_quantity` VARCHAR(50), IN `in_price` VARCHAR(50), IN `in_amount` VARCHAR(50), IN `in_remarks` VARCHAR(100), IN `in_status` VARCHAR(50), IN `in_expense` VARCHAR(100), IN `in_facilityId` VARCHAR(50), IN `in_type_of_expenses` VARCHAR(100))  NO SQL BEGIN

INSERT INTO expense(date,month,branch_name,request_no,particulars,quantity,price,amount,remarks,status,expense_id,facilityId,type_of_expenses)
        VALUES(in_date,in_month,in_branch_name,in_request_no,in_particulars,in_quantity,
        in_price,in_amount,in_remarks,in_status,in_expense,in_facilityId,in_type_of_expenses);
        call update_number_generator("exp",in_request_no);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_new_drug` (IN `drug` VARCHAR(50), IN `unit_of_issue` VARCHAR(30), IN `quantity` INT(11), IN `price` INT(11), IN `expiry_date` VARCHAR(20), IN `generic` VARCHAR(50), IN `reorderlevel` VARCHAR(10), IN `expiryalert` VARCHAR(10), IN `facId` VARCHAR(50))   BEGIN
    INSERT INTO drugs (drug,genericName,expiry_date,quantity,price,unit_of_issue,reorder_level,expiryAlert,facilityId) VALUES (drug,generic,expiry_date,quantity,price,unit_of_issue,reorderlevel,expiryalert,facId);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_new_lab_head` (IN `labhead` VARCHAR(50), IN `labsubhead` VARCHAR(50), IN `spec` VARCHAR(50), IN `facId` VARCHAR(50), IN `descr` VARCHAR(50), IN `no_of_label` VARCHAR(50))   BEGIN
    INSERT INTO lab_setup(head, subhead, description, facilityId, specimen, noOfLabels,sort_index) VALUES (labhead, labsubhead,descr , facId,spec,no_of_label,1);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_new_lab_service` (IN `labhead` VARCHAR(50), IN `labsubhead` VARCHAR(50), IN `unit` VARCHAR(50), IN `test` VARCHAR(50), IN `facId` VARCHAR(50), IN `test_from` VARCHAR(50), IN `test_to` VARCHAR(50), IN `spec` VARCHAR(50), IN `test_price` INT, IN `userId` VARCHAR(50), IN `descr` VARCHAR(50), IN `no_of_labels` INT, IN `in_percentage` INT, IN `in_index` INT)   BEGIN
    INSERT INTO lab_setup(head, subhead, description, noOfLabels, unit, facilityId, range_from, range_to, specimen, price, percentage, created_by,sort_index) VALUES (labhead, labsubhead, descr, no_of_labels, unit, facId, test_from, test_to, spec, test_price, in_percentage, userId,in_index);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_new_store` (IN `in_receive_date` VARCHAR(20), IN `in_item_name` VARCHAR(50), IN `in_po_no` VARCHAR(20), IN `in_qty_in` VARCHAR(50), IN `in_qty_out` VARCHAR(50), IN `in_store_type` VARCHAR(20), IN `in_grm_no` VARCHAR(20), IN `query_type` VARCHAR(20), IN `in_expiring_date` VARCHAR(20), IN `in_unit_price` VARCHAR(30), IN `in_mark_up` VARCHAR(20), IN `in_selling_price` VARCHAR(10), IN `in_transfer_from` VARCHAR(50), IN `in_status` VARCHAR(20), IN `in_transfer_to` VARCHAR(50), IN `in_branch_name` VARCHAR(30), IN `in_facilityId` VARCHAR(50), IN `in_trn_no` INT(50), IN `in_uniqueId` VARCHAR(50), IN `in_item_category` VARCHAR(100))  NO SQL BEGIN
if query_type= "received" then
##update purchase_order set status="received" where po_id=in_po_no;
INSERT INTO store (receive_date, item_name, po_no, qty_in,qty_out,store_type,grm_no,expiring_date,unit_price,mark_up,selling_price,transfer_from,transfer_to, branch_name,facilityId,uniqueId,item_category) VALUES(in_receive_date,in_item_name,in_po_no,in_qty_in, in_qty_out,in_store_type,in_grm_no, in_expiring_date,in_unit_price,in_mark_up,in_selling_price,in_transfer_from,in_transfer_to,in_branch_name,in_facilityId,in_uniqueId,in_item_category);
call update_number_generator("grn",in_grm_no);

ELSEIF query_type="transfer" then
INSERT INTO store (receive_date, item_name, po_no, qty_in,qty_out,store_type,grm_no,expiring_date,unit_price,mark_up,selling_price,transfer_from,transfer_to, branch_name,facilityId,trn_number,uniqueId,item_category) VALUES(in_receive_date,in_item_name,in_po_no,in_qty_in, in_qty_out,in_store_type,in_grm_no, in_expiring_date,in_unit_price,in_mark_up,in_selling_price,in_transfer_from,in_transfer_to,in_branch_name,in_facilityId,in_trn_no,uniqueId,in_item_category);

call add_sale_department(in_trn_no,in_item_name,in_qty_out,in_expiring_date,in_selling_price,in_transfer_to,in_receive_date,in_item_category);
end if;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_new_supplier` (IN `name` VARCHAR(50), IN `address` VARCHAR(255), IN `phone` VARCHAR(20), IN `code` VARCHAR(10), IN `facId` VARCHAR(50))   BEGIN
       INSERT INTO suppliersinfo(supplier_name, address, phone, code,facilityId) VALUES (name,address,phone,code,facId);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_purchase_order` (IN `in_po_no` INT(40), IN `in_date` DATE, IN `in_type` VARCHAR(50), IN `in_vendor` VARCHAR(100), IN `in_client` VARCHAR(100), IN `in_total_amount` VARCHAR(100), IN `in_status` VARCHAR(100), IN `in_facilityId` VARCHAR(50), IN `in_exchange_type` VARCHAR(50), IN `in_exchange_rate` INT(50), IN `in_supplier_code` INT(10), IN `in_processed_by` VARCHAR(50))  NO SQL BEGIN 
INSERT INTO purchase_order(po_id,date,type,vendor,client,total_amount,status,facilityId,exchange_type,exchange_rate,supplier_code,processed_by)VALUES
(in_po_no,in_date,in_type,in_vendor,in_client,in_total_amount,in_status,in_facilityId,in_exchange_type,in_exchange_rate,in_supplier_code,in_processed_by);
call update_number_generator("po",in_po_no);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_purchase_order_list` (IN `in_exchange_rate` INT(50), IN `in_item_name` VARCHAR(100), IN `in_specification` VARCHAR(100), IN `in_quantity_available` INT(100), IN `in_propose_quantity` INT(100), IN `in_price` INT(100), IN `in_propose_amount` INT(100), IN `in_exchange_type` VARCHAR(50), IN `in_po_id` VARCHAR(50), IN `in_type` VARCHAR(100), IN `in_identifier` VARCHAR(100), IN `in_facilityId` VARCHAR(100), IN `in_date` DATE, IN `in_status` VARCHAR(100), IN `in_remark` VARCHAR(100), IN `in_remarks_id` VARCHAR(50), IN `in_item_category` VARCHAR(100), IN `in_expired_status` VARCHAR(11))  NO SQL INSERT INTO purchase_order_list(
      exchange_rate,
      item_name,
      specification,
      quantity_available,
      propose_quantity,
      price,
      propose_amount,
  
      exchange_type,
      po_id,
      type,
      identifier,
    remark,
    remarks_id,
      facilityId,
    date,
    status,
    item_category,
    expired_status
      )
      VALUES(
          in_exchange_rate,
      in_item_name,
      in_specification,
      in_quantity_available,
      in_propose_quantity,
      in_price,
      in_propose_amount,
    
      in_exchange_type,
      in_po_id,
      in_type,
      in_identifier,
          in_remark,
          in_remarks_id,
      in_facilityId,
          in_date,
          in_status,
          in_item_category,
          in_expired_status
      )$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_sale_department` (IN `in_trn_number` INT(50), IN `in_item_name` VARCHAR(100), IN `in_qty_in` INT(100), IN `in_expiring_date` VARCHAR(100), IN `in_selling_price` INT(100), IN `in_branch_location` VARCHAR(100), IN `in_transaction_date` VARCHAR(20), IN `in_item_category` VARCHAR(50))  NO SQL BEGIN
INSERT INTO sale_department(trn_number,	item_name,	qty_in	,expiring_date,	selling_price	,location_from,location_to,transaction_date,qty_out,item_category) VALUES(in_trn_number,in_item_name,in_qty_in,in_expiring_date,in_selling_price,in_branch_location,"pos",in_transaction_date,0,in_item_category);

UPDATE sale_department SET selling_price=in_selling_price WHERE item_name=in_item_name AND location_from=in_branch_location;
-- INSERT INTO branch_store(trn_number,item_name,qty_out,expiring_date,selling_price,location_to,location_from,transaction_date) VALUES(in_trn_number,in_item_name,in_qty_in,in_expiring_date,in_selling_price,in_branch_location,"pos",in_transaction_date);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `appointment` (IN `in_user_id` VARCHAR(30), IN `patient_id` VARCHAR(20), IN `patient_n` VARCHAR(90), IN `appointType` VARCHAR(50), IN `loc` VARCHAR(70), IN `in_text` VARCHAR(100), IN `in_from` DATETIME, IN `in_to` DATETIME, IN `facId` VARCHAR(60), IN `query_type` VARCHAR(40), IN `in_id` VARCHAR(11))   BEGIN
IF query_type = 'insert' THEN
INSERT INTO `appointment`(user_id,`patientId`, `patient_name`, `appointmentType`, `location`, `notes`, `start_at`, `end_at`, `facilityId`) VALUES (in_user_id,patient_id,patient_n,appointType,loc,in_text,in_from,in_to,facId);
ELSEIF query_type = 'select' THEN
SELECT * from appointment WHERE facilityId=facId AND user_id=in_user_id;
ELSEIF query_type = 'select_user' THEN
SELECT * from appointment WHERE facilityId=facId AND patientId=patient_id;
ELSEIF query_type = 'select_one' THEN
SELECT * from appointment WHERE id=in_id AND facilityId=facId;
ELSEIF query_type = 'delete' THEN
DELETE from appointment WHERE id=in_id AND facilityId=facId;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `assign` (IN `doctor` VARCHAR(20), IN `patientId` VARCHAR(10), IN `facId` VARCHAR(50), IN `in_query_type` VARCHAR(50), IN `in_status` VARCHAR(50), IN `in_consultation_number` VARCHAR(50))   BEGIN
  IF in_query_type = 'assign' THEN
    UPDATE patientrecords 
    SET 
      assigned_to = doctor, 
      date_assigned = NOW(), 
      status = in_status, 
      consultation_number = in_consultation_number
    WHERE 
      id = patientId 
      AND facilityId = facId;

  ELSEIF in_query_type = 'waiting' THEN
    SELECT 
      CONCAT(firstname, ' ', surname) AS name, 
      id, 
      date_assigned, 
      consultation_number 
    FROM patientrecords 
    WHERE 
      assigned_to = 'waiting' 
      AND status = 'waiting' 
      AND facilityId = facId 
    ORDER BY date_assigned ASC;

  ELSEIF in_query_type = 'specialists' THEN
    SELECT 
      CONCAT(a.firstname, ' ', a.surname) AS name, 
      a.id, 
      date_assigned, 
      consultation_number, 
      CONCAT(b.firstname, ' ', b.lastname) AS doctorName 
    FROM patientrecords a 
    JOIN users b ON a.assigned_to = b.username 
    WHERE 
      assigned_to != '' 
      AND assigned_to != 'waiting' 
      AND a.status = 'waiting' 
      AND a.facilityId = facId 
    ORDER BY date_assigned ASC;

  ELSEIF in_query_type = 'by_doc' THEN
    SELECT 
      CONCAT(firstname, ' ', surname) AS name, 
      id, 
      date_assigned  
    FROM patientrecords 
    WHERE 
      assigned_to = doctor 
      AND facilityId = facId 
      AND status = 'waiting';
      
  ELSEIF in_query_type = 'triage' THEN
  SELECT
      CONCAT(firstname, ' ', surname) AS name, 
      patient_id AS allocation_id,
      date_assigned, 
      consultation_number,
      assigned_to
    FROM patientrecords 
    WHERE 
      assigned_to != ''
      AND status = 'waiting' 
      AND facilityId = facId;

  ELSEIF in_query_type = 'end' THEN
    UPDATE patientrecords
    SET 
      assigned_to = '', 
      date_assigned = NULL
    WHERE 
      id = patientId 
      AND facilityId = facId;

  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `bed_allocation` (IN `in_query_type` VARCHAR(20), IN `in_bed` VARCHAR(50), IN `in_user` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `in_date` TIMESTAMP, IN `in_patientId` VARCHAR(50), IN `in_allocation_id` VARCHAR(50), IN `in_status` VARCHAR(20))  NO SQL IF in_query_type = 'new' THEN
	INSERT INTO bed_allocation (bed_id,patient_id,allocated,allocation_status,allocated_by,facilityId) VALUES (in_bed, in_patientId, in_date,in_status, in_user, in_facId);
    UPDATE patientrecords SET patientStatus='admitted', date_seen='', seen_by='' WHERE id=in_patientId AND facilityId=in_facId;
    
ELSEIF in_query_type = 'discharge' THEN
	UPDATE bed_allocation SET ended=in_date, allocation_status='discharged', ended_by='' WHERE id=in_allocation_id;
    UPDATE patientrecords SET patientStatus='', date_seen = NOW(), seen_by='' WHERE id=in_patientId AND facilityId=in_facId;
    
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `charges` (IN `p_id` VARCHAR(20), IN `u_id` VARCHAR(20), IN `amt` FLOAT, IN `in_cr` FLOAT, IN `decr` VARCHAR(100), IN `in_status` VARCHAR(30), IN `facId` VARCHAR(60), IN `date_from` DATE, IN `date_to` DATE, IN `query_type` VARCHAR(20), IN `patient_type` VARCHAR(30))   BEGIN
 declare old_balance int;
 declare main_balance int;
 declare paid_balance int;
 declare new_amt int;
 select balance into old_balance  from hospitals where  id=facId;
 set main_balance = old_balance + amt;
 set paid_balance = old_balance - in_cr;

IF query_type = 'insert'  THEN
 IF in_status ='Follow-up' THEN
 SET new_amt = amt DIV 2;
 ELSE
 SET new_amt = amt;
 END IF;
INSERT INTO `charges_fees`(`patient_id`, `user_id`,`dr`, `cr`, `description`, `status`,facilityId,patientType) VALUES (p_id,u_id,new_amt,in_cr,decr,in_status,facId,patient_type);
IF amt > 0 then	
UPDATE `hospitals` SET `balance`=main_balance WHERE id = facId;
ELSE
UPDATE `hospitals` SET `balance`=paid_balance WHERE id = facId;
END IF;

ELSEIF query_type = 'select' THEN
SELECT * FROM charges_fees where facilityId=facId AND date(created_at) BETWEEN date(date_from) AND date(date_to) ORDER BY id DESC;
ELSEIF query_type = 'select_charges' THEN
SELECT * FROM charges_fees where description=decr AND facilityId=facId AND date(created_at) BETWEEN date(date_from) AND date(date_to) ORDER BY id DESC;
ELSEIF query_type = 'balance' THEN
SELECT balance from hospitals WHERE id = facId;
ELSEIF query_type = 'last' THEN
SELECT created_at FROM `charges_fees` WHERE patient_id='7401-1' AND dr != 0 AND dr >150 ORDER BY created_at DESC LIMIT 1;
ELSEIF query_type = 'select_time' THEN 
SELECT time_laps FROM charges_fees_temp WHERE revenueSource = 'Consultation';
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `charges_temp` (IN `head` INT, IN `query_type` VARCHAR(20))   BEGIN
IF query_type = 'select' THEN
SELECT DISTINCT revenueSource FROM charges_fees_temp;
ELSE
SELECT amount,revenueSource FROM `charges_fees_temp` WHERE accountHead=head;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `consultation_record` (IN `in_query_type` VARCHAR(50), IN `in_consultation_note` VARCHAR(4000), IN `in_decision` VARCHAR(50), IN `in_dressing_request` VARCHAR(500), IN `in_nursing_request` VARCHAR(500), IN `in_user_id` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `in_consult_id` VARCHAR(90), IN `in_pid` VARCHAR(100), IN `in_treatment_plan` VARCHAR(4000), IN `in_report_type` VARCHAR(50), IN `in_date` VARCHAR(50), IN `in_admissionStatus` VARCHAR(50), IN `dateFrom` DATE, IN `dateTo` DATE, IN `in_patient_name` VARCHAR(100), IN `created_by` VARCHAR(70), IN `in_icd_code` VARCHAR(255), IN `in_icd_name` VARCHAR(255))  NO SQL IF in_query_type = 'insert' THEN
        INSERT INTO consultations (id, consultation_notes,userId, decision, dressing_request, nursing_request,facilityId,patient_id,treatmentPlan,patient_name,seen_by, icd_code,icd_name) VALUES (in_consult_id, in_consultation_note, in_user_id, in_decision, in_dressing_request, in_nursing_request,in_facId,in_pid,in_treatment_plan,in_patient_name,created_by,in_icd_code,in_icd_name);
        IF in_admissionStatus = 'pending' THEN
                IF in_decision = 'discharge' THEN
                    UPDATE patientrecords SET patientStatus='pending-discharge', seen_by=in_user_id, date_seen=now() WHERE id=in_pid AND facilityId=in_facId;
                ELSE
                    UPDATE patientrecords SET patientStatus='pending-admission', seen_by=in_user_id, date_seen=now() WHERE id=in_pid AND facilityId=in_facId;
                END IF;
        END IF;

ELSEIF in_query_type = 'update' THEN
UPDATE consultations SET consultation_notes=in_consultation_note, treatmentPlan=in_treatment_plan WHERE id=in_consult_id;

ELSEIF in_query_type = 'list by patient' THEN
        IF in_report_type = 'by_date' THEN
        SELECT a.id, a.patient_id, a.userId, concat(b.firstname,' ',b.lastname) as reviewedBy, a.consultation_notes, a.treatmentPlan, a.decision, a.dressing_request, a.nursing_request, a.nursing_request_status, a.facilityId, a.created_at FROM consultations a JOIN users b ON a.userId = b.username WHERE patient_id=in_pid AND date(created_at)=in_date ORDER BY created_at DESC;
    ELSE
                SELECT a.id, a.patient_id, a.userId, concat(b.firstname,' ',b.lastname) as reviewedBy, a.consultation_notes, a.treatmentPlan, a.decision, a.dressing_request, a.nursing_request, a.nursing_request_status, a.facilityId, a.created_at FROM consultations a JOIN users b ON a.userId = b.username WHERE patient_id=in_pid ORDER BY created_at DESC;
    END IF;
ELSEIF in_query_type = 'by_id' THEN
        SELECT * FROM consultations WHERE id=in_consult_id;
ELSEIF in_query_type = 'pending nursing requests' THEN
        SELECT id, nursing_request,dressing_request, nursing_request_status,treatmentPlan FROM consultations WHERE nursing_request_status='pending' AND facilityId=in_facId;
ELSEIF in_query_type='nursing_req_by_patient' THEN
        SELECT a.id, a.created_at, nursing_request,dressing_request, nursing_request_status, concat(b.firstname,' ',b.lastname) as doctor_name FROM consultations a JOIN users b ON a.userId = b.username WHERE a.facilityId=b.facilityId AND patient_id=in_pid AND nursing_request_status='pending' AND  a.facilityId=in_facId AND (nursing_request!='' OR dressing_request!='') ORDER BY a.created_at DESC;
ELSEIF in_query_type='treatment_plan_by_patient' THEN
        SELECT a.id, a.created_at, treatmentPlan, concat(b.firstname,' ',b.lastname) as doctor_name FROM consultations a JOIN users b ON a.userId = b.username WHERE a.facilityId=b.facilityId AND patient_id=in_pid AND treatment_plan_status='pending' AND  a.facilityId=in_facId AND treatmentPlan!='' ORDER BY a.created_at DESC;
ELSEIF in_query_type = 'complete nursing req' THEN
        UPDATE consultations SET nursing_request_status='completed' WHERE id=in_consult_id;
ELSEIF in_query_type = 'treatment-done' THEN
        UPDATE consultations SET treatment_plan_status='completed', treatment_by=in_user_id WHERE id=in_consult_id;
ELSEIF in_query_type = 'visit_days' THEN
        SELECT DISTINCT date(created_at) as created_at FROM consultations WHERE patient_id=in_pid ORDER BY created_at DESC;
ELSEIF in_query_type = 'surgery_days' THEN
        SELECT DISTINCT date(createdAt) as created_at FROM operationnotes WHERE patientId=in_pid ORDER BY createdAt DESC;
        ELSEIF in_query_type = 'history' THEN
  SELECT a.patient_id, a.userId, a.consultation_notes, a.treatmentPlan, a.decision, a.dressing_request, a.nursing_request, a.nursing_request_status, a.facilityId, a.created_at, a.treatment_plan_status, a.treatment_by, concat(b.surname, ' ', b.firstname, ' ', ifnull(b.other, '')) as full_name FROM `consultations` a JOIN patientrecords b WHERE a.patient_id=b.id and a.facilityId=b.facilityId AND a.userId=in_user_id AND a.facilityId=in_facId AND DATE(a.created_at) BETWEEN date(dateFrom) AND date(dateTo) ORDER BY a.created_at DESC;
END if$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createbooking_list` (IN `in_request_id` VARCHAR(50))  NO SQL BEGIN
	DECLARE test_data,department_data INTEGER;
	declare finished integer default 0;
	DECLARE print_type_data,patient_id_data,test_group_data varchar(100) ;
	

	DEClARE curLabtest 
		CURSOR FOR 
        
            SELECT test,print_type,department,patient_id,test_group FROM lab_requisition where  request_id=in_request_id;
            
            
	-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;

	OPEN curLabtest;

	getLab: LOOP
		FETCH curLabtest INTO test_data,print_type_data,department_data,patient_id_data,test_group_data;

		
		IF finished = 1 THEN 
			LEAVE getLab;
		END IF;
		
    if  print_type_data='single' then 
		BLOCK2: begin
                declare maxCode, labCodeNumber int;
                declare no_more_rows2 integer default 0;
                declare cursor2 cursor for
                   
 		        select  max(booking)+1,concat(year_code,max(booking)+1) from booking_no GROUP by year_code;
		
                declare continue handler for not found
                    set no_more_rows2 =1;
                open cursor2;
                LOOP2: loop
                    fetch cursor2 into  maxCode, labCodeNumber;
                    
                    
                    update lab_requisition set booking_no=labCodeNumber where test=test_data and print_type='single' and
                        request_id=in_request_id ;
            
                    update booking_no set booking=maxcode;
    
	
                    if no_more_rows2 =1 then
                        close cursor2;
                        leave LOOP2;
                    end if;
	

                end loop LOOP2;
            end BLOCK2;
    elseif  print_type_data = 'grouped' then 
		BLOCK2: begin
                declare maxCode, labCodeNumber int;
                declare no_more_rows2 integer default 0;
                declare cursor2 cursor for
                   
 		        select  max(booking)+1,concat(year_code,max(booking)+1) from booking_no GROUP by year_code;
		
                declare continue handler for not found
                    set no_more_rows2 =1;
                open cursor2;
                LOOP2: loop
                    fetch cursor2 into  maxCode, labCodeNumber;
                    
                    update lab_requisition set booking_no=labCodeNumber where  department=department_data and print_type = 'grouped' and  request_id=in_request_id;

                update booking_no set booking=maxcode;
                    if no_more_rows2 =1 then
                        close cursor2;
                        leave LOOP2;
                    end if;
		

                

                end loop LOOP2;
               
            end BLOCK2;

    elseif  print_type_data='singular_group' then 
		BLOCK2: begin
                declare maxCode, labCodeNumber int;
                declare no_more_rows2 integer default 0;
                declare cursor2 cursor for
                   
 		 select  max(booking)+1,concat(year_code,max(booking)+1) from booking_no GROUP by year_code;
		
                declare continue handler for not found
                    set no_more_rows2 =1;
                open cursor2;
                LOOP2: loop
                    fetch cursor2 into  maxCode, labCodeNumber;
                    
                    
                    update lab_requisition set booking_no=labCodeNumber where  department=department_data and print_type='singular_group' 
                        and request_id=in_request_id;
                    update booking_no set booking=maxcode;
	
	
                    if no_more_rows2 =1 then
                        close cursor2;
                        leave LOOP2;
                    end if;
		

                end loop LOOP2;
               	
            end BLOCK2;
    
	 end if;

	END LOOP getLab;
	CLOSE curLabtest;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createlabcode_list` (IN `in_request_id` VARCHAR(100))   BEGIN
	DECLARE test_data,department_data, test_group_data INTEGER;
	declare finished integer default 0;
	DECLARE booking_no_data,label_type_data,patient_id_data varchar(100) ;
	

	DEClARE curLabtest 
		CURSOR FOR 
        
			SELECT booking_no,test,label_type,department,patient_id,test_group FROM lab_requisition where  request_id=in_request_id;
            
            
        

	-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;

	OPEN curLabtest;

	getLab: LOOP
		FETCH curLabtest INTO booking_no_data,test_data,label_type_data,department_data,patient_id_data,test_group_data;

		
		IF finished = 1 THEN 
			LEAVE getLab;
		END IF;
		
  if  label_type_data='single' then 
		BLOCK2: begin
                declare maxCode, barcodeNumber int;
                declare no_more_rows2 integer default 0;
                declare cursor2 cursor for
                   
 		 select  max(barcode)+1,concat(initials,year_code,max(barcode)+1) from barcode where lab_code=department_data;
		
                declare continue handler for not found
                    set no_more_rows2 =1;
                open cursor2;
               LOOP2: loop
                    fetch cursor2 into  maxCode, barcodeNumber;
                    
                    
 update lab_requisition set code=barcodeNumber where booking_no=booking_no_data and test=test_data and label_type='single' and  request_id=in_request_id ;
		
    update barcode set barcode=maxcode where lab_code=department_data;
    
	
                    if no_more_rows2 =1 then
                        close cursor2;
                        leave LOOP2;
                    end if;
		



                end loop LOOP2;
            end BLOCK2;
elseif  label_type_data = 'grouped' then 
		BLOCK2: begin
                declare maxCode, barcodeNumber int;
                declare no_more_rows2 integer default 0;
                declare cursor2 cursor for
                   
 		 select  max(barcode)+1,concat(initials,year_code,max(barcode)+1) from barcode where lab_code=department_data;
		
                declare continue handler for not found
                    set no_more_rows2 =1;
                open cursor2;
               LOOP2: loop
                    fetch cursor2 into  maxCode, barcodeNumber;
                    
                    
                    if no_more_rows2 =1 then
                        close cursor2;
                        leave LOOP2;
                    end if;
		

 update lab_requisition set code=barcodeNumber where department=department_data and label_type = 'grouped' and  request_id=in_request_id;
           update barcode set barcode=maxcode where lab_code=department_data;

                end loop LOOP2;
               
            end BLOCK2;

            elseif  label_type_data='grouped_single' then 
		BLOCK2: begin
                declare maxCode, barcodeNumber int;
                declare no_more_rows2 integer default 0;
                declare cursor2 cursor for
                   
 		 select  max(barcode)+1,concat(initials,year_code,max(barcode)+1) from barcode where lab_code=department_data;
		
                declare continue handler for not found
                    set no_more_rows2 =1;
                open cursor2;
               LOOP2: loop
                    fetch cursor2 into  maxCode, barcodeNumber;
                    
                    
  update lab_requisition set code=barcodeNumber where  label_type='grouped_single'and  request_id=in_request_id and test_group=test_group_data;
                update barcode set barcode=maxcode where lab_code=department_data;
	
	
                    if no_more_rows2 =1 then
                        close cursor2;
                        leave LOOP2;
                    end if;
		

            

                end loop LOOP2;
               	
            end BLOCK2;
    
	 end if;

	END LOOP getLab;
	CLOSE curLabtest;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `create_bed` (IN `in_query_type` VARCHAR(20), IN `in_id` INT(11), IN `in_class` VARCHAR(20), IN `in_price` INT, IN `in_bed` VARCHAR(100), IN `in_facId` VARCHAR(50), IN `noOfBeds` INT, IN `in_status` VARCHAR(50))  NO SQL IF in_query_type  = 'newBed' THEN
	INSERT INTO bedlist (class_type, price, name,facilityId,no_of_beds) VALUES (in_class, in_price, in_bed,in_facId,noOfBeds);
    
    ELSEIF in_query_type = 'updateBed' THEN
        UPDATE bedlist
        SET class_type = in_class,
        price = in_price,
            name = in_bed,
            no_of_beds = noOfBeds
        WHERE id = in_id;
        
        ELSEIF in_query_type = 'disableBed' THEN
        UPDATE bedlist
        SET status = 'disabled'
        WHERE id = in_id;

END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `create_bedb4` (IN `in_query_type` VARCHAR(20), IN `in_class` VARCHAR(20), IN `in_price` INT, IN `in_bed` VARCHAR(100), IN `in_facId` VARCHAR(50), IN `noOfBeds` INT)  NO SQL IF in_query_type  = 'newBed' THEN
	INSERT INTO bedlist (class_type, price, name,facilityId,no_of_beds) VALUES (in_class, in_price, in_bed,in_facId,noOfBeds);
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `create_discount` (IN `in_query_type` VARCHAR(50), IN `in_discount_type` VARCHAR(50), IN `in_discount_name` VARCHAR(50), IN `in_discount_amount` INT, IN `in_discount_head` VARCHAR(50), IN `in_discount_head_name` VARCHAR(50), IN `in_user` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `in_receiptNo` VARCHAR(50))  NO SQL IF in_query_type = 'new' THEN
	INSERT INTO discount (discountName, discountType, discountAmount, discountHead, discountHeadName,created_by,facilityId) VALUES (in_discount_name, in_discount_type, in_discount_amount, in_discount_head, in_discount_head_name,in_user,in_facId);
ELSEIF in_query_type = 'select' THEN
	SELECT * FROM discount WHERE facilityId=in_facId;
ELSEIF in_query_type = 'pending' THEN
	SELECT patient_name, created_at, SUM(price) as total_amount, receiptNo, discount, discount_head, discount_amount FROM lab_requisition WHERE approval_status = 'pending_discount' AND facilityId = in_facId GROUP BY patient_name, created_at, discount, discount_head, discount_amount;
ELSEIF in_query_type = 'approval' THEN
	update lab_requisition SET approval_status = 'pending' WHERE receiptNo=in_receiptNo AND facilityId=in_facId;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `create_new_client_acc` (IN `accType` VARCHAR(20), IN `s_name` VARCHAR(50), IN `f_name` VARCHAR(50), IN `p_gender` VARCHAR(20), IN `dob` DATE, IN `maritalStatus` VARCHAR(20), IN `p_occupation` VARCHAR(20), IN `address` VARCHAR(100), IN `depositAmount` INT, IN `in_modeOfPayment` VARCHAR(20), IN `c_name` VARCHAR(50), IN `c_address` VARCHAR(100), IN `c_phone` VARCHAR(20), IN `c_email` VARCHAR(50), IN `web` VARCHAR(20), IN `facId` VARCHAR(50), IN `userId` VARCHAR(50), IN `patientId` VARCHAR(50), IN `kName` VARCHAR(200), IN `kPhone` VARCHAR(100), IN `kRel` VARCHAR(20), IN `kEmail` VARCHAR(50), IN `kAddress` VARCHAR(200), IN `in_receiptsn` VARCHAR(50), IN `in_receiptno` VARCHAR(50), IN `in_sourceAcct` VARCHAR(50), IN `paybles_head` VARCHAR(50), IN `recievables_head` VARCHAR(50), IN `in_description` VARCHAR(50), IN `in_type` VARCHAR(50))  NO SQL BEGIN
	DECLARE acc_no INT;
    select ifnull(max(accountNo), 0) + 1 INTO acc_no FROM patientfileno WHERE facilityId=facId;
    
    IF in_type = 'update' THEN
    	INSERT INTO patientfileno (accountNo, facilityId,accountType,accName,contactName,
                                       contactAddress,contactPhone, contactEmail, contactWebsite,
                                       firstname,surname) 
               VALUES (acc_no, facId, accType, concat(s_name,' ',f_name), c_name, 
                                               c_address, c_phone, c_email, web, f_name, s_name);
		UPDATE patientrecords set accountNo=acc_no, beneficiaryNo=1, id=concat(acc_no,'-',1) WHERE patient_id = patientId AND facilityId=facId;
    
    ELSE
    	IF accType = 'family' THEN
        	INSERT INTO patientfileno (accountNo, facilityId,accountType,accName,contactName,
                                       contactAddress,contactPhone, contactEmail, contactWebsite,
                                       firstname,surname) 
               VALUES (acc_no, facId, accType, concat(s_name,' ',f_name), c_name, 
                                               c_address, c_phone, c_email, web, f_name, s_name);
        	INSERT INTO patientrecords (accountNo, beneficiaryNo, id, facilityId,surname,firstname,
                                        gender,maritalstatus,DOB,phoneNo,email, occupation,
                                        address,patient_id,kinName,kinRelationship,kinPhone,
                                        kinEmail,kinAddress) 
               VALUES (acc_no,1,concat(acc_no,'-',1), facId,s_name,f_name,gender,maritalStatus, dob, 
                                                c_phone,c_email,p_occupation, c_address, 
                                                patientId,kName,kRel,kPhone,kEmail,kAddress);

    	ELSE
        	INSERT INTO patientfileno (accountNo,facilityId,accountType,contactName,contactAddress,contactPhone,contactEmail, contactWebsite,description,accName) VALUES (acc_no,facId,accType,c_name,c_address,c_phone,c_email,web,f_name,s_name);

    	END IF;
    END IF;
    
    IF depositAmount > 0 THEN
    	CALL customer_deposit(acc_no,depositAmount,userId,in_receiptsn, in_receiptno, in_description, in_modeOfPayment, facId,in_sourceAcct,concat(s_name,' ', f_name),accType,NOW(),c_address,c_phone,c_email,web,paybles_head,recievables_head,'','','','');
   	END IF;
    
COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `create_new_lab_client` (IN `client_acc` VARCHAR(50), IN `acc_no` VARCHAR(50), IN `ben_no` VARCHAR(50), IN `first_name` VARCHAR(50), IN `last_name` VARCHAR(50), IN `other_name` VARCHAR(50), IN `p_gender` VARCHAR(50), IN `birth` DATE, IN `mail` VARCHAR(50), IN `facId` VARCHAR(50), IN `labno` VARCHAR(50), IN `phone` VARCHAR(13))   BEGIN 

INSERT INTO patientrecords (accountNo,beneficiaryNo,id,firstname,surname,other,Gender, DOB,email,facilityId,phoneNo) VALUES (acc_no,ben_no,CONCAT(acc_no,'-',ben_no),first_name, last_name,other_name, p_gender,birth,mail,facId,phone); 


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `create_org_acc` (IN `in_acct` VARCHAR(50), IN `Amount_paid` INT, IN `userId` VARCHAR(50), IN `receiptDateSN` VARCHAR(20), IN `receiptNo` VARCHAR(20), IN `modeOfPayment` VARCHAR(30), IN `in_facId` VARCHAR(50), IN `in_cash_head` VARCHAR(50), IN `acc_name` VARCHAR(100), IN `acc_type` VARCHAR(20), IN `in_date` DATETIME, IN `in_address` VARCHAR(50), IN `in_phone` VARCHAR(20), IN `in_email` VARCHAR(50), IN `in_website` VARCHAR(50), IN `in_payables_head` VARCHAR(50), IN `in_recievables_head` VARCHAR(50), IN `in_guarantor_name` VARCHAR(100), IN `in_guarantor_address` VARCHAR(100), IN `in_guarantor_phone` VARCHAR(20), IN `in_bank_name` VARCHAR(30), IN `in_pid` VARCHAR(20), IN `in_txn_status` VARCHAR(50), IN `in_description` VARCHAR(200))   BEGIN

DECLARE next_payable_code VARCHAR(20);
DECLARE next_receivable_code VARCHAR(20);

CALL customer_deposit(in_acct, Amount_paid,userId,receiptDateSN,receiptNo,
        in_description,modeOfPayment,in_facId,in_cash_head,acc_name,acc_type,in_date,
in_address,in_phone,in_email,in_website,in_payables_head,in_recievables_head,in_guarantor_name,
        in_guarantor_address,in_guarantor_phone,in_bank_name,in_pid,in_txn_status);

SELECT ifnull(max(head), 0) + 1 into next_payable_code FROM account where subhead=in_payables_head
        AND facilityId=in_facId;
SELECT ifnull(max(head), 0) + 1 into next_receivable_code FROM account where subhead=in_recievables_head
        AND facilityId=in_facId;

call new_acc_head(concat(acc_name, ' Payables'),in_payables_head,next_payable_code,0,in_facId,0);
call new_acc_head(concat(acc_name, ' Receivables'),in_recievables_head,next_receivable_code,0,in_facId,0);
UPDATE patientfileno SET payable_head=next_payable_code, payable_head_name=concat(acc_name, ' Payables'), receivable_head=next_receivable_code, receivable_head_name=concat(acc_name, ' Receivables') WHERE accountNo=in_acct AND facilityId=in_facId;

end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `customer_deposit` (IN `in_acct` INT, IN `amount_paid` INT, IN `userId` VARCHAR(50), IN `in_receiptDateSN` VARCHAR(50), IN `in_receiptSN` VARCHAR(50), IN `in_description` VARCHAR(1000), IN `in_mode_of_payment` VARCHAR(60), IN `in_facId` VARCHAR(50), IN `sourceAcct` VARCHAR(50), IN `acc_name` VARCHAR(100), IN `acc_type` VARCHAR(20), IN `in_date` DATETIME, IN `in_address` VARCHAR(100), IN `in_phone` VARCHAR(20), IN `in_email` VARCHAR(50), IN `in_website` VARCHAR(50), IN `in_payables_head` VARCHAR(50), IN `in_recievables_head` VARCHAR(50), IN `in_guarantor_name` VARCHAR(50), IN `in_guarantor_address` VARCHAR(100), IN `in_guarantor_phone` VARCHAR(20), IN `in_bank_name` VARCHAR(50), IN `in_pid` VARCHAR(50), IN `in_txn_status` VARCHAR(50))   BEGIN
	declare client_balance double;
	declare main_balance double;
    #DECLARE remaining_balance double;
	select balance into client_balance from patientfileno where accountNo=in_acct AND facilityId=in_facId LIMIT 1;

	#SET remaining_balance = Amount_paid - client_balance;
	set main_balance = client_balance+Amount_paid;

	-- # IF customer is a NEW client,
    -- # We create a new account for the customer and deposit the amount
	if client_balance is null and amount_paid < 0 then
  
        	insert into patientfileno (accountNo,accName,balance,facilityId,status,accountType,contactAddress,contactPhone,contactEmail,contactWebsite,guarantor_name,
               guarantor_address,guarantor_phone)
		values(in_acct,acc_name,Amount_paid,in_facId,'approved',acc_type,in_address,in_phone,in_email,in_website,in_guarantor_name,
               in_guarantor_address,in_guarantor_phone);

       insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt,client_id,txn_status)
		values (in_acct,abs(Amount_paid),0,in_receiptDateSN,in_description,in_facId,in_date,in_pid,in_txn_status);
        
		insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,
                                  patient_id,facilityId,createdAt,bank_name)
		values (in_description,sourceAcct,abs(Amount_paid),0,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                userId,in_acct,in_acct,in_facId,in_date,in_bank_name);

		insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,
                                  patient_id,facilityId,createdAt,bank_name)
		values (in_description,in_recievables_head,0,abs(Amount_paid) ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                userId,in_acct,in_acct,in_facId,in_date,in_bank_name);
            
            
            
            
            
            ELSEif client_balance is null then
    
		insert into patientfileno (accountNo,accName,balance,facilityId,status,accountType,contactAddress,contactPhone,contactEmail,contactWebsite,guarantor_name,
               guarantor_address,guarantor_phone)
		values(in_acct,acc_name,Amount_paid,in_facId,'approved',acc_type,in_address,in_phone,in_email,in_website,in_guarantor_name,
               in_guarantor_address,in_guarantor_phone);

       insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt,client_id,txn_status)
		values (in_acct,abs(Amount_paid),0,in_receiptDateSN,in_description,in_facId,in_date,in_pid,in_txn_status);
        
		insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,
                                  client_acct,patient_id,facilityId,createdAt,bank_name)
		values (in_description,sourceAcct,abs(Amount_paid),0,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                userId,in_acct,in_acct,in_facId,in_date,in_bank_name);

		insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,
                                  client_acct,patient_id,facilityId,createdAt,bank_name)
		values (in_description,in_payables_head,0,abs(Amount_paid) ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                userId,in_acct,in_acct,in_facId,in_date,in_bank_name);

	end if;
    
    -- # IF customer has an account, but the deposit amount nullifies his account balance
    -- # i.e. he's paying up his debt
	if  main_balance = 0 then
 
		update patientfileno set balance= main_balance  where accountNo=in_acct AND facilityId=in_facId;

		insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt,client_id,txn_status)
		values (in_acct,abs(Amount_paid),0,in_receiptDateSN,in_description,in_facId,in_date,in_pid,in_txn_status);
		 
		insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment, enteredBy,
                                  client_acct,patient_id,facilityId,createdAt,bank_name)
		values (in_description,sourceAcct,abs(Amount_paid),0,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                userId,in_acct,in_acct,in_facId,in_date,in_bank_name);

		insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment, enteredBy,
                                  client_acct,patient_id,facilityId,createdAt,bank_name)
		values (in_description,in_recievables_head,0,abs(client_balance) ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                userId,in_acct,in_acct,in_facId,in_date,in_bank_name);

	-- # IF customer has an account, and his new account balance after the deposit is a top up
    -- # to his initial account balance
	elseif main_balance  > 0  then
 
		update patientfileno set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

		insert into account_entries (acct,dr,cr, reference_no, description, facilityId, createdAt,client_id,txn_status)
		values (in_acct,Amount_paid,0,in_receiptDateSN, in_description,in_facId, in_date,in_pid,in_txn_status);

		insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,
                                  client_acct,patient_id,facilityId,createdAt,bank_name)
		values (in_description,sourceAcct,abs(Amount_paid),0,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                userId,in_acct,in_acct,in_facId,in_date,in_bank_name);

		-- # IF customer's was owing us some money, then
		if  client_balance < 0 then

			insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,
                                      client_acct,patient_id,facilityId,createdAt,bank_name)
			values (in_description,in_recievables_head,0,abs(client_balance) ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                    userId,in_acct,in_acct,in_facId,in_date,in_bank_name);

			insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,
                                      client_acct,patient_id,facilityId,createdAt,bank_name)
			values (in_description,in_payables_head,0,abs(main_balance) ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                    userId,in_acct,in_acct,in_facId,in_date,in_bank_name);
            
		-- # ELSE IF customer had some money in his/her account
		elseif client_balance >= 0 then
			insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,
                                      client_acct,patient_id,facilityId,createdAt,bank_name)
			values (in_description,in_payables_head,0,abs(Amount_paid) ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                    userId,in_acct,in_acct,in_facId,in_date,in_bank_name);
		end if;

	-- # IF the customer was owing some money and the deposit amount is not upto the amount owed
	elseif main_balance  < 0 then
		update patientfileno set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

		insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt,client_id,txn_status)
		values (in_acct,abs(Amount_paid),0,in_receiptDateSN,in_description,in_facId,in_date,in_pid,in_txn_status);

		insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,
                                  modeOfPayment,enteredBy,
                                  client_acct,patient_id,facilityId,createdAt,bank_name)
		values (in_description,sourceAcct,abs(Amount_paid),0,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
                userId,in_acct,in_acct,in_facId,in_date,in_bank_name);
        
		insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,
                                  enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name)
		values (in_description,in_recievables_head,0,abs(Amount_paid) ,in_receiptDateSN,
                in_receiptSN,in_mode_of_payment,userId,in_acct,in_acct,in_facId,in_date,in_bank_name);
        
        
	end if;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteOperationNote` (IN `in_id` INT, IN `facId` VARCHAR(50))  NO SQL DELETE FROM operationnotes where id=in_id and facilityId=facId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_drug` (IN `drugId` VARCHAR(11), IN `facId` VARCHAR(50))   BEGIN
    DELETE FROM drugs WHERE drug_id = drugId AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_service` (IN `serviceId` VARCHAR(11), IN `facId` VARCHAR(50))   BEGIN
    DELETE FROM services WHERE service_id = serviceId AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_supplier` (IN `supplierId` VARCHAR(50), IN `facId` VARCHAR(50))   BEGIN
	DELETE FROM suppliersinfo WHERE id=supplierId AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_user` (IN `id` INT(100), IN `facilityId` INT(20))  NO SQL DELETE FROM `users` WHERE `users`.`id` = id AND facilityId = facilityId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `department` (IN `in_query_type` VARCHAR(10), IN `in_facId` VARCHAR(50), IN `in_name` VARCHAR(50), IN `in_user_id` VARCHAR(50))  NO SQL if in_query_type = 'new' THEN
	INSERT INTO department (dept_name, created_by, facilityId) VALUES (in_name,in_user_id,in_facId);
ELSEIF in_query_type = 'get' THEN
	SELECT * FROM department WHERE facilityId=in_facId;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deposit` (IN `amt` INT, IN `patientId` VARCHAR(50), IN `descr` VARCHAR(100), IN `source_head` VARCHAR(100), IN `userId` VARCHAR(50), IN `receiptsn` VARCHAR(50), IN `receiptno` VARCHAR(50), IN `payment_mode` VARCHAR(50), IN `dest_head` VARCHAR(100), IN `facId` VARCHAR(100), IN `in_date` DATETIME)  NO SQL BEGIN 
  DECLARE acc_balance int;
  SELECT balance INTO acc_balance FROM patientfileno WHERE accountNo = patientId AND facilityId=facId;
  UPDATE patientfileno SET balance = acc_balance + amt WHERE accountNo = patientId AND facilityId=facId;
  INSERT INTO transactions (description, acct, debit, credit, enteredBy, receiptDateSN, receiptNo, modeOfPayment,client_acct,facilityId,createdAt) 
    VALUES (descr,source_head,0,amt,userId,receiptsn,receiptno,payment_mode,patientId,facId,in_date);
  INSERT INTO transactions (description, acct, debit, credit, enteredBy, receiptDateSN, receiptNo, modeOfPayment,client_acct,facilityId, createdAt) 
    VALUES (descr,dest_head,amt,0,userId,receiptsn,receiptno,payment_mode,patientId,facId,in_date);
  
  COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `discharge_reports` (IN `p_patient_id` VARCHAR(50), IN `p_report_text` TEXT, IN `p_doctor_id` VARCHAR(50), IN `p_admission_id` VARCHAR(50))   BEGIN
    INSERT INTO discharge_reports (
        patient_id,
        report_text,
        doctor_id,
        admission_id,
        created_at,
        updated_at
    ) VALUES (
        p_patient_id,
        p_report_text,
        p_doctor_id,
        p_admission_id,
        NOW(),
        NOW()
    );
    
    -- Update admission status to discharged
    -- UPDATE in_patient_list 
    -- SET status = 'discharged', 
       -- discharge_date = NOW(),
       -- updated_at = NOW()
  --  WHERE patient_id = p_patient_id 
    -- AND id = p_admission_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `doctorLabRequest` (IN `in_department` VARCHAR(50), IN `in_test` VARCHAR(100), IN `in_percentage` VARCHAR(5), IN `in_price` VARCHAR(11), IN `in_code` VARCHAR(50), IN `in_noOfLabels` VARCHAR(7), IN `in_test_group` VARCHAR(30), IN `in_print_type` VARCHAR(30), IN `in_label_type` VARCHAR(30), IN `in_patient_id` VARCHAR(50), IN `in_requested_by` VARCHAR(50), IN `in_facilityId` VARCHAR(50), IN `in_status` VARCHAR(11), IN `query_type` VARCHAR(20), IN `in_req_id` VARCHAR(50), IN `in_description` VARCHAR(100), IN `in_patient_status` VARCHAR(20), IN `in_from` VARCHAR(20), IN `in_to` VARCHAR(20), IN `in_created_by` VARCHAR(50), IN `in_receiptDateSN` VARCHAR(50), IN `in_payment_status` VARCHAR(20), IN `in_old_price` VARCHAR(10), IN `in_payables_head` VARCHAR(10), IN `in_recievables_head` VARCHAR(10), IN `in_account` VARCHAR(10), IN `in_account_name` VARCHAR(50), IN `in_patient_name` VARCHAR(100), IN `in_department_code` VARCHAR(10), IN `in_unit_code` VARCHAR(10), IN `in_unit_name` VARCHAR(50), IN `in_unit` VARCHAR(10), IN `in_range_from` VARCHAR(10), IN `in_range_to` VARCHAR(10), IN `in_client_type` VARCHAR(20), IN `in_client_account` VARCHAR(10), IN `in_discount` VARCHAR(10), IN `in_discount_head` VARCHAR(10), IN `in_discount_head_name` VARCHAR(50), IN `in_approval_status` VARCHAR(20), IN `in_discount_amount` VARCHAR(10), IN `in_request_id` VARCHAR(20), IN `in_transaction_id` VARCHAR(100))  NO SQL BEGIN
IF query_type= 'insert' THEN

    INSERT INTO lab_requisition(test,patient_id,facilityId,price,percentage,
        department,test_group,status,created_by,receiptNo,payment_status,label_type,noOfLabels,
        print_type,payable_head,receivable_head,account,account_name,
        patient_name,department_code,unit_code,unit_name,unit,range_from,range_to,client_type,
        client_account,discount,discount_head,discount_head_name,approval_status,discount_amount,request_id, patient_status, requested_by,description) 
    VALUES (in_test,in_patient_id,in_facilityId,in_price,in_percentage,in_department,in_test_group,
        in_status,in_created_by,in_receiptDateSN,in_payment_status,in_label_type,in_noOfLabels,
        in_print_type,in_payables_head,in_recievables_head,in_account,in_account_name,
        in_patient_name,in_department_code,in_unit_code,in_unit_name,in_unit,in_range_from, in_range_to,
        in_client_type,in_client_account,in_discount,in_discount_head,in_discount_head_name,in_approval_status,
        in_discount_amount,in_req_id,in_patient_status,in_requested_by,in_description);
    COMMIT;
    IF in_price > 0 THEN
    INSERT INTO pending_txn (facilityId,transaction_id, description, head, subhead, amount, service_type, created_at, 
    patient_name, patient_id, total_amount,client_acc, tx_status, patient_type) VALUES (in_facilityId, in_req_id, in_description, '',
    in_account, in_price, 'LAB', now(), in_patient_name, in_patient_id, 0, in_client_account, 'pending', in_client_type);
END IF;

ELSEIF query_type='ordered_list' THEN 
SELECT patient_name as name, created_at, patient_id,'' as DOB,request_id, patient_status FROM lab_requisition 
WHERE status='ordered' AND date(created_at) BETWEEN date(in_from) AND date(in_to) GROUP BY patient_id;

ELSEIF query_type = 'lab_processed' THEN
UPDATE lab_requisition SET status = 'Sample Collected' WHERE request_id = in_transaction_id;
   call createbooking_list(in_req_id);
  call  createlabcode_list(in_req_id);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `drug_expiry_alert` (IN `facId` VARCHAR(50))   BEGIN
    SELECT * FROM drugpurchaserecords WHERE DATE_FORMAT(expiry_date, '%Y-%m-%d') BETWEEN DATE_FORMAT(NOW(), '%Y-%m-%d') AND DATE_FORMAT(DATE_ADD(NOW(),INTERVAL 6 MONTH), '%Y-%m-%d') AND (facilityId=facId) ORDER by expiry_date ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `drug_freq_setup` (IN `in_query_type` VARCHAR(50), IN `in_desc` VARCHAR(100), IN `in_time` VARCHAR(10), IN `in_time_int` INT)  NO SQL IF in_query_type = 'hours' THEN
	SELECT * FROM hour_list;
ELSEIF in_query_type = 'new' THEN 
	INSERT INTO drug_frequency4 (description, time, drug_time) VALUES (in_desc, in_time, in_time_int);
ELSEIF in_query_type = 'list' THEN
	SELECT * FROM drug_frequency4;
ELSEIF in_query_type = 'delete' THEN
	DELETE FROM drug_frequency4 WHERE description=in_desc;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `drug_qtty_alert` (IN `facId` VARCHAR(50))   BEGIN
    SELECT * FROM drugpurchaserecords WHERE drugpurchaserecords.balance < drugpurchaserecords.reorder_level AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `drug_schedule` (IN `in_patient_id` VARCHAR(50))  NO SQL BEGIN
	DECLARE finished INTEGER DEFAULT 0;
	DECLARE id_data varchar(150) DEFAULT "";
	

	DEClARE curLabtest 
		CURSOR FOR 
        
			SELECT id   FROM dispensary WHERE patient_id=in_patient_id AND schedule_status='pending';

            
            
	-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;

	OPEN curLabtest;

	getLab: LOOP
		FETCH curLabtest INTO id_data ;

		
		IF finished = 1 THEN 
			LEAVE getLab;
		END IF;
		
 
		BLOCK2: begin
                DECLARE id_data2, patient_id_data, drug_data,frequency_data, facilityId_data, prescribed_by_data varchar(150) DEFAULT "";
		DECLARE duration_data, no_of_days_data,times_per_day_data, drug_count_data, no_times_data int;
		DECLARE startTime_data,end_date_data DATETIME;

		DECLARE i,d datetime default '0000-00-00 00:00:00';
    		declare j int default 0;
		
                declare no_more_rows2 integer default 0;
                declare cursor2 cursor for
                   
 		 SELECT id, patient_id, drug, duration, no_of_days, frequency, startTime, times_per_day, end_date, drugCount,
          facilityId, prescribed_by, no_times  
                        FROM dispensary WHERE id=id_data;

		
                declare continue handler for not found
                    set no_more_rows2 =1;
                open cursor2;
               LOOP2: loop
                    fetch cursor2 INTO id_data, patient_id_data, drug_data, duration_data, no_of_days_data, 
                        frequency_data, startTime_data, times_per_day_data, end_date_data, drug_count_data, facilityId_data,
                        prescribed_by_data, no_times_data;
                    
			   
                IF i< startTime_data then
                    set i=startTime_data;
                    set d=end_date_data;
                end if;
                WHILE i <=d  and j < drug_count_data DO
                INSERT INTO drug_schedule( time_stamp,	drug_name, patient_id,prescription_id, facilityId, administered_by ) 
                    VALUES(i,drug_data,patient_id_data,id_data,facilityId_data, prescribed_by_data) ;
                    SET i = (select DATE_ADD((select max(time_stamp) from drug_schedule where prescription_id=id_data ), INTERVAL no_times_data hour) );
                    set j = j + 1;   
                END WHILE;
                
	CALL update_dispensary('new schedule', 'scheduled', id_data);
                    if no_more_rows2 =1 then
                        close cursor2;
                        leave LOOP2;
                    end if;
		



                end loop LOOP2;
            end BLOCK2;

	 

	END LOOP getLab;
	CLOSE curLabtest;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `drug_verification` (IN `in_drug_name` VARCHAR(100), IN `in_item_code` VARCHAR(100))   SELECT * FROM pharm_store WHERE drug_name = in_drug_name AND balance > 0 AND (DATE(expiry_date) > now() OR expiry_date = '1111-11-11') ORDER BY expiry_date DESC LIMIT 1$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `fetch_by_doctor` (IN `doctor` VARCHAR(20), IN `facId` VARCHAR(50))   BEGIN
    select * from patientrecords where assigned_to = doctor AND facilityId=facId limit 20;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `fluid_chart` (IN `in_patient_id` VARCHAR(50), IN `in_input_volume` VARCHAR(50), IN `in_input_route` VARCHAR(30), IN `in_input_type` VARCHAR(50), IN `in_output_volume` VARCHAR(50), IN `in_output_route` VARCHAR(30), IN `in_output_type` VARCHAR(55), IN `in_created_at` DATETIME, IN `query_type` VARCHAR(30), IN `in_created_by` VARCHAR(50))   BEGIN
IF query_type='insert' THEN
INSERT INTO `fluid_chart`(`patient_id`, `input_volume`, `input_route`, `input_type`, `output_volume`, `output_route`, `output_type`, `created_at`, created_by) VALUES (in_patient_id,in_input_volume,input_route,in_input_type,in_output_volume,in_output_route,in_output_type,in_created_at,in_created_by);
ELSEIF query_type='select' THEN 
SELECT * FROM fluid_chart WHERE patient_id=in_patient_id;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `frequency_test` (IN `in_param` VARCHAR(50), IN `in_curr_hour` TIME, IN `in_date` DATE, IN `in_no_of_days` INT)   BEGIN

 select distinct no_times, description,time_TEST(in_param,in_curr_hour, `in_date`) next_time, date_add(time_TEST(in_param,in_curr_hour, `in_date`), INTERVAL in_no_of_days day) end_time,
 COUNT(description) no_of_times, in_no_of_days * COUNT(description) as drug_count FROM drug_frequency4 WHERE description=in_param;

end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `generate_consultation_number` (IN `p_prefix` VARCHAR(10), IN `p_description` VARCHAR(100), IN `p_doctor_id` VARCHAR(50), OUT `p_generated_number` VARCHAR(100))   BEGIN
    DECLARE v_date VARCHAR(8) DEFAULT DATE_FORMAT(CURDATE(), '%Y%m%d');
    DECLARE v_prefix VARCHAR(20); -- Increased size to accommodate all prefix types
    DECLARE v_next_num INT;
    
    -- Determine prefix based on type
    IF p_prefix = 'DOC' AND p_doctor_id IS NOT NULL THEN
        -- Doctor-specific consultation (DOC-DRJ-20231225)
        SET v_prefix = CONCAT('DOC-', UPPER(SUBSTRING(p_doctor_id, 1, 3)), '-', v_date);
    ELSEIF p_prefix = 'WL' THEN
        -- Waiting list (WL-20231225)
        SET v_prefix = CONCAT('WL-', v_date);
    ELSE
        -- General consultation (CON-20231225)
        SET v_prefix = CONCAT('CON-', v_date);
    END IF;
    
    -- Get or create sequence
    INSERT INTO number_generator (description, prefix, code_no)
    VALUES (
        CONCAT(p_description, ' on ', CURDATE()),
        v_prefix,
        1
    )
    ON DUPLICATE KEY UPDATE code_no = code_no + 1;
    
    -- Get the current sequence number
    SELECT code_no INTO v_next_num 
    FROM number_generator 
    WHERE prefix = v_prefix;
    
    -- Format the final number based on type
    IF p_prefix = 'DOC' AND p_doctor_id IS NOT NULL THEN
        -- DOC-DRJ-20231225-001
        SET p_generated_number = CONCAT('DOC-', UPPER(SUBSTRING(p_doctor_id, 1, 3)), '-', v_date, '-', LPAD(v_next_num, 3, '0'));
    ELSEIF p_prefix = 'WL' THEN
        -- WL-20231225-001
        SET p_generated_number = CONCAT('WL-', v_date, '-', LPAD(v_next_num, 3, '0'));
    ELSE
        -- CON-20231225-001
        SET p_generated_number = CONCAT('CON-', v_date, '-', LPAD(v_next_num, 3, '0'));
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getLabReceipt` (IN `in_receiptNo` VARCHAR(50), IN `in_facilityId` VARCHAR(50), IN `in_query_type` VARCHAR(50))  NO SQL IF in_query_type = 'summary' THEN
SELECT description as patient_name, sum(debit) as amount, receiptDateSN as receiptNo FROM transactions3 WHERE receiptDateSN = in_receiptNo AND facilityId=in_facilityId;
ELSE 
SELECT description, price, patient_id,created_at,created_by as enteredBy,modeOfPayment FROM  lab_info    WHERE receiptNo = in_receiptNo AND price >0  AND facilityId=in_facilityId;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getQTY` (IN `in_item_name` VARCHAR(40))  NO SQL SELECT SUM(qty_in-qty_out) as qty FROM `store` WHERE item_name=in_item_name$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getReturnDrug` (IN `in_recepit` INT(20), IN `in_drug_code` INT(20))   SELECT * FROM drugs WHERE receipt_no=in_recepit AND drug=in_drug_code AND source='sold_items'$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getUnitOfIssue` (IN `drugName` VARCHAR(50), IN `facId` VARCHAR(50))   BEGIN
	SELECT DISTINCT unit_of_issue FROM drugs WHERE  drug = drugName AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_account` (IN `facId` VARCHAR(50))   BEGIN
    select ifnull(max(accountNo),0) + 1 as 'max(accountNo) + 1' from patientrecords WHERE facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_acc_chart` (IN `facId` VARCHAR(50))   BEGIN
	SELECT head as title,subhead,description,price FROM account WHERE facilityId=facId;
    #SELECT head,subhead title FROM account WHERE facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_acc_head_for_acc` (IN `in_description` VARCHAR(100), IN `in_facId` VARCHAR(50))  NO SQL SELECT * from account where description=in_description AND facilityId=in_facId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all` (IN `facId` VARCHAR(50))   BEGIN
    select * from patientrecords WHERE facilityId=facId limit 50;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_acc_heads` (IN `facId` VARCHAR(50))   BEGIN
    SELECT head, subhead, description FROM account WHERE facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_consultation` (IN `date_from` DATE, IN `date_to` DATE, IN `doc_name` VARCHAR(50), IN `query_type` VARCHAR(30), IN `facId` VARCHAR(80))   BEGIN
IF query_type='select_all' THEN
SELECT * from consultations WHERE facilityId=facId AND DATE(created_at) BETWEEN DATE(date_from) AND DATE(date_to);

ELSEIF query_type='select_discharge' THEN
SELECT *, b.name AS bedName FROM view_all_bed_allocations a JOIN bedlist b ON a.bed_id=b.id  WHERE a.facilityId=facId AND DATE(a.created_at) BETWEEN DATE(date_from) AND DATE(date_to);

ELSEIF query_type = 'select_by_doc' THEN
SELECT * from consultations WHERE userId=doc_name AND facilityId=facId AND DATE(created_at) BETWEEN DATE(date_from) AND DATE(date_to);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_lab_services` (IN `facId` VARCHAR(50), IN `in_query_type` VARCHAR(50), IN `in_description` VARCHAR(100))  NO SQL IF in_query_type = 'search' THEN
	SELECT head as subhead, subhead as title, department_code,unit_code,unit_name, unit, range_from, range_to, account,account_name, payable_head,payable_head_name, receivable_head,receivable_head_name, description, price, old_price, noOfLabels, label_type,specimen, percentage, sort_index, qms_dept_id, selectable, collect_sample, to_be_analyzed, to_be_reported, print_type, upload_doc FROM lab_setup WHERE facilityId=facId AND description like in_description AND selectable != 'not allowed';
ELSEIF in_query_type = 'children' THEN
SELECT head as subhead, subhead as title, department_code,unit_code,unit_name, unit, range_from, range_to, account,account_name, payable_head,payable_head_name, receivable_head,receivable_head_name, description, price, old_price, noOfLabels, label_type,specimen, percentage, sort_index, qms_dept_id, selectable, collect_sample, to_be_analyzed, to_be_reported, print_type, upload_doc FROM lab_setup WHERE facilityId=facId AND head = in_description;
ELSE
	SELECT head as subhead, subhead as title, department_code,unit_code,unit_name, unit, range_from, range_to, account,account_name, payable_head,payable_head_name, receivable_head,receivable_head_name, description, price, old_price, noOfLabels, label_type,specimen, percentage, sort_index, qms_dept_id, selectable, collect_sample, to_be_analyzed, to_be_reported, print_type, upload_doc FROM lab_setup WHERE facilityId=facId;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_op_notes` (IN `facId` VARCHAR(50))   BEGIN
    SELECT * FROM operationnotes WHERE facilityId=facId ORDER BY id DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_patient_trans` (IN `in_client_id` VARCHAR(30), IN `date_from` VARCHAR(20), IN `date_to` VARCHAR(20), IN `facId` VARCHAR(60), IN `query_type` VARCHAR(30))   BEGIN
IF query_type = 'drug' THEN
SELECT * FROM `account_entries` WHERE client_id = in_client_id AND facilityId=facId AND date(createdAt) BETWEEN date_from AND date_to AND quantity > 0;
ELSEIF query_type='test' THEN
SELECT * FROM `account_entries` WHERE client_id = in_client_id AND facilityId=facId AND date(createdAt) BETWEEN date_from AND date_to AND quantity = 0 AND dr = 0;

END if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_prescriptions` (IN `facId` VARCHAR(50))   BEGIN
    SELECT *  FROM prescriptionrequests WHERE facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_services` (IN `facId` VARCHAR(50))   BEGIN
   SELECT * FROM `services` WHERE facilityId=facId ORDER BY createdAt DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_suppliers` (IN `facId` VARCHAR(50))   BEGIN
SELECT * FROM suppliersinfo WHERE facilityId=facId ORDER BY date DESC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_transactions` (IN `facId` VARCHAR(50))   BEGIN
    SELECT * from `transactions` WHERE facilityId=facId ORDER BY createdAt DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_all_user_byId` (IN `in_id` INT, IN `facId` VARCHAR(50))  NO SQL SELECT * FROM users where id = in_id AND facilityId = facId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_amount_handed_over` (IN `userId` VARCHAR(50), IN `date` DATE, IN `facId` VARCHAR(50))   BEGIN
    SELECT sum(ifnull(amountHandedOver,0)) as amountHandedover FROM transfers WHERE transfer_from = userId and date(date) = date AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_amount_received` (IN `userId` VARCHAR(10), IN `date` DATE, IN `facId` VARCHAR(50))   BEGIN
    SELECT sum(amountReceived) as amountReceived FROM transfers WHERE transfer_to = userId AND date(date) = date AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_avail_receipt_no` (IN `facId` VARCHAR(50))   BEGIN
    SELECT max(receiptNo) + 1 FROM `transactions` WHERE DATE_FORMAT(createdAt, "%d%m%y") = DATE_FORMAT(NOW(), "%d%m%y") AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_balance` (IN `accNo` VARCHAR(10), IN `facId` VARCHAR(50))   BEGIN
    SELECT balance, accName as name, firstname, surname FROM `patientfileno` WHERE accountNo = accNo AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_beds` (IN `in_query_type` VARCHAR(20), IN `in_facId` VARCHAR(50), IN `in_status` VARCHAR(50))  NO SQL IF in_query_type = 'classes' THEN
	SELECT DISTINCT class_type FROM bedlist WHERE facilityId=in_facId;
ELSEIF in_query_type = 'bedlist' THEN
	SELECT * FROM bedlist_view WHERE facilityId=in_facId;
ELSEIF in_query_type = 'available' THEN
	SELECT * FROM bedlist_view WHERE occupied != no_of_beds AND status='enable' AND facilityId=in_facId;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_bedss` (IN `in_query_type` VARCHAR(20), IN `in_facId` VARCHAR(50))  NO SQL IF in_query_type = 'classes' THEN
	SELECT DISTINCT class_type FROM bedlist WHERE facilityId=in_facId;
ELSEIF in_query_type = 'bedlist' THEN
	SELECT * FROM bedlist_view WHERE facilityId=in_facId;
ELSEIF in_query_type = 'available' THEN
	SELECT * FROM bedlist_view WHERE occupied != no_of_beds AND facilityId=in_facId;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_beneficiary_no` (IN `accNo` VARCHAR(10), IN `facId` VARCHAR(50))   BEGIN
	SELECT count(id) + 1 as beneficiaryNo FROM patientrecords where accountNo = accNo;
    #AND facilityId=facId;
    # SELECT IFNULL(MAX(beneficiaryNo),0) + 1 as beneficiaryNo from patientrecords where accountNo = accNo AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_best_selling_staff` (IN `facId` VARCHAR(50), IN `dateFrom` DATE, IN `dateTo` DATE)  NO SQL SELECT SUM(a.qty_out) + SUM(a.price) AS amount, concat(b.firstname, ' ', b.lastname) as staff FROM drugs a JOIN users b on a.created_by = b.id WHERE date(a.created_at) BETWEEN date(dateFrom) AND date(dateTo) AND a.source='dispensary' AND a.facilityId=facId GROUP BY staff ORDER BY amount DESC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_client_accounts` (IN `in_facId` VARCHAR(50))  NO SQL SELECT * FROM patientfileno WHERE facilityId=in_facId AND accountType !='Walk-In' AND accountType !='Family'$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_client_acc_stmt` (IN `clientId` VARCHAR(20), IN `dateFrom` DATE, IN `dateTo` DATE, IN `facId` VARCHAR(50))   BEGIN
	SELECT acct, description, dr as debit, cr as credit, reference_no, createdAt from account_entries WHERE 
    acct=clientId AND
     date(createdAt) BETWEEN date(dateFrom) AND date(dateTo) AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_deposit_acc_head` (IN `facId` VARCHAR(50))   BEGIN
    SELECT head FROM account WHERE head = 'Deposit' AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_diagnoses_by_id` (IN `patientId` VARCHAR(20), IN `facId` VARCHAR(50))   BEGIN
    SELECT *  FROM diagnosis where patient_id = patientId AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_discharge_patient` (IN `p_patient_id` VARCHAR(50))   BEGIN
    SELECT * FROM pending_txn 
   WHERE patient_id = p_patient_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_dispensary_records` (IN `facId` VARCHAR(50))  NO SQL BEGIN
    SELECT concat(a.drug, ' (', a.generic_name,')') as drug,a.cost_price,a.balance as quantity, dispensary_balance as dispensary_quantity ,a.expiry_date,a.created_at,b.supplier_name as supplier 
    FROM drugpurchaserecords a JOIN suppliersinfo b ON a.supplier=b.id WHERE a.facilityId=facId AND dispensary_balance!=0 ORDER BY created_at DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_doctors` (IN `facId` VARCHAR(50), IN `in_query_type` VARCHAR(20))   BEGIN
    IF in_query_type = 'specialist' THEN
        -- Get specialist doctors (excluding General practitioners)
        SELECT * FROM users 
        WHERE LOWER(role) = 'Doctor' 
        AND speciality != 'General' 
        AND speciality != '' 
        AND facilityId = facId
        AND status = 'approved'
        ORDER BY firstname, lastname;
    ELSE
        -- Get all doctors for the facility
        SELECT * FROM users 
        WHERE LOWER(role) = 'Doctor' 
        AND facilityId = facId
        AND status = 'approved'
        ORDER BY firstname, lastname;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_drugs_list` (IN `facId` VARCHAR(50))   BEGIN
    SELECT SUM(quantity) as quantity, drug from drugpurchaserecords WHERE facilityId=facId GROUP BY drug;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_drugs_sold` (IN `facId` VARCHAR(50), IN `dateFrom` DATE, IN `dateTo` DATE)  NO SQL SELECT SUM(qty_out) AS quantity, drug FROM drugs WHERE date(created_at) BETWEEN date(dateFrom) AND date(dateTo) AND source='dispensary' AND facilityId=facId GROUP BY drug  ORDER BY quantity DESC LIMIT 5$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_drug_freq` (IN `facId` VARCHAR(50), IN `in_query_type` VARCHAR(50), IN `in_param` VARCHAR(50), IN `in_curr_hour` VARCHAR(20), IN `in_date` DATE, IN `in_no_of_days` INT)  NO SQL IF in_query_type = 'freq_details' THEN
call frequency_test(in_param, in_curr_hour, in_date, in_no_of_days);

#select distinct no_times, description,time_TEST(in_param,in_curr_hour, `in_date`) next_time, COUNT(description) no_of_times FROM drug_frequency4 WHERE description=in_param;
	#SELECT description, no_times, time_TEST(in_param, in_curr_hour, `in_date`) next_time, COUNT(description) no_of_times FROM drug_frequency4 WHERE description=in_param;

ELSE
	SELECT description FROM drug_frequency;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_drug_price_by_id` (IN `id` INT(4), IN `facId` VARCHAR(50))   BEGIN
    SELECT price FROM `drugs` WHERE drug_id=id AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_expenses_acc_heads` (IN `facId` VARCHAR(50))   BEGIN
    SELECT head, description from account where subhead like '3%' AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_expired_drugs` (IN `facId` VARCHAR(50))   BEGIN
    SELECT * FROM `drugs` WHERE DATE_FORMAT(expiry_date, '%Y-%m-%d') < DATE_FORMAT(NOW(), '%Y-%m-%d') AND (facilityId=facId);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_facility_info` (IN `fac_id` VARCHAR(50))  NO SQL SELECT *, id as facility_id, name as facility_name FROM hospitals WHERE id = fac_id$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_homepage` (IN `in_facId` VARCHAR(50), IN `in_role` VARCHAR(30))  NO SQL SELECT home_page FROM pagenavigation WHERE role = in_role AND facilityId=in_facId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_id` (IN `facId` VARCHAR(50))   BEGIN
    select ifnull(max(accountNo), 0) + 1 as nextId from patientrecords WHERE facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_ids` (IN `facId` VARCHAR(50))   BEGIN
    select distinct accountNo from patientrecords WHERE facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_individual_report` (IN `account` VARCHAR(10), IN `fromDate` VARCHAR(30), IN `toDate` VARCHAR(30), IN `facId` VARCHAR(50))   BEGIN
    SELECT * FROM `transactions` WHERE (transaction_source=account OR destination = account) AND (createdAt BETWEEN fromDate AND toDate) AND (facilitatorId = facId);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_inventory` ()  NO SQL SELECT * from list_items WHERE balance>0$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_item_category` (IN `in_subhead` VARCHAR(50), IN `in_fadId` VARCHAR(50))  NO SQL SELECT * FROM `item_description` where subhead = in_subhead and facilityId=in_fadId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_lab` (IN `in_query_type` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `in_status` VARCHAR(50))  NO SQL BEGIN
	IF in_query_type = 'sample collection' THEN
    	SELECT DISTINCT concat(b.surname, ' ', b.firstname) as name,a.booking_no as labno,  code,
        COUNT(DISTINCT department) AS no_of_tests, department_head AS department, a.patient_id
        FROM lab_process a JOIN patientrecords b ON a.patient_id=b.patient_id 
        WHERE a.status = in_status AND a.facilityId=in_facId AND b.facilityId=in_facId
        GROUP BY booking_no,name;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_lab_by_booking` (IN `in_booking` VARCHAR(20), IN `in_facId` VARCHAR(50), IN `in_dept` VARCHAR(50))  NO SQL IF in_dept='all' THEN
SELECT distinct booking_no, department, status, specimen, description, subhead as test,
        group_head, sn, price, old_price,
        ifnull(sop_instance_id, '') sop_instance_id, unit, range_from, range_to, ifnull(result,'') result,
        ifnull(appearance, '') appearance, ifnull(serology, '') serology,ifnull(culture_yielded, '') culture_yielded,
        IFNULL(sensitivity, '') AS sensitiveTo, IFNULL(intermediaryTo, '') AS intermediaryTo, IFNULL(resistivity, '')
        AS resistantTo, sample_collected_by, sample_collected_at,department_head, commission_type, percentage,
        report_type, print_type, IFNULL(o_value,'') as o_value, IFNULL(h_value,'') as h_value, created_at
        FROM lab_process
        WHERE booking_no=in_booking
        AND status IN ('Sample Collected', 'analyzed', 'result','saved', "printed", "uploaded")
        AND test != test_group
        AND facilityId=in_facId
        ORDER BY created_at DESC;
ELSE
        SELECT distinct booking_no, department, status, specimen, description, subhead as test,
        group_head, sn, price, old_price,
        ifnull(sop_instance_id, '') sop_instance_id, ifnull(n_unit,unit) as unit, ifnull(n_range_from,range_from) as range_from, ifnull(n_range_to,range_to) as range_to, ifnull(result,'') result,
        ifnull(appearance, '') appearance, ifnull(serology, '') serology,ifnull(culture_yielded, '') culture_yielded,
        IFNULL(sensitivity, '') AS sensitiveTo, IFNULL(intermediaryTo, '') AS intermediaryTo, IFNULL(resistivity, '')
        AS resistantTo, sample_collected_by, sample_collected_at,department_head, commission_type, percentage,
        report_type, print_type, IFNULL(o_value,'') as o_value, IFNULL(h_value,'') as h_value
        FROM lab_process
        WHERE booking_no=in_booking AND (department_head=in_dept OR department=in_dept)
        AND status IN ('Sample Collected', 'analyzed', 'result','saved', "printed", "uploaded")
        AND test != test_group
        AND facilityId=in_facId
        ORDER BY created_at DESC;
END if$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_lab_by_status` (IN `in_query_type` INT, IN `in_status` INT, IN `facId` INT)  NO SQL IF in_query_type = 'list' THEN
	SELECT a.booking_no, concat(b.firstname, ' ', b.surname) as name,a.patient_id,a.created_at,
        a.department
        FROM lab_requisition a JOIN patientrecords b ON a.patient_id=b.id
        WHERE a.status IN (in_status) AND
        a.facilityId=facId AND b.facilityId=facId
        GROUP BY booking_no,a.patient_id,date(a.created_at),name
        order by a.created_at DESC;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_lab_list` (IN `in_query_type` VARCHAR(10), IN `in_facId` VARCHAR(50), IN `in_pid` VARCHAR(50), IN `date_from` DATE, IN `date_to` DATE)  NO SQL IF in_query_type = 'all' THEN
	SELECT a.booking_no, concat(b.firstname, ' ', b.surname) as name,a.patient_id,a.created_at,a.department,count(a.status) as tests,
    (SELECT COUNT(*) FROM lab_requisition WHERE status IN ('pending') AND booking_no=a.booking_no ) as pending,
	(SELECT COUNT(*) FROM lab_requisition WHERE status IN ('Sample Collected', 'saved') AND booking_no=a.booking_no ) as collected,
	(SELECT COUNT(*) FROM lab_requisition WHERE status IN ('analyzed') AND booking_no=a.booking_no ) as analyzed,
    (SELECT COUNT(*) FROM lab_requisition WHERE status='result' AND booking_no=a.booking_no AND facilityId=in_facId) as completed
		FROM lab_requisition a JOIN patientrecords b ON a.patient_id=b.id 
        WHERE a.facilityId=in_facId AND a.status!='printed'
        AND (a.created_at BETWEEN date(date_from) AND date(date_to)) AND b.facilityId=in_facId 
        GROUP BY booking_no, a.patient_id, a.created_at, name order by count(a.status)-completed, count(a.status)-analyzed, 
        a.created_at DESC;
    ELSE
    	
       SELECT booking_no, patient_id,created_at,department,count(status) as tests,(SELECT COUNT(*) FROM lab_requisition WHERE status='result' AND booking_no=booking_no AND facilityId=in_facId) as completed
		FROM lab_requisition WHERE patient_id=in_pid AND facilityId=in_facId GROUP BY booking_no, created_at order by count(status)-completed, created_at DESC;
        END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_lab_requisitions` (IN `facId` VARCHAR(50))  NO SQL SELECT concat(firstname, ' ', surname) as name, id, dateCreated FROM `patientrecords` WHERE status = 'lab_requisition' AND facilityId=facId ORDER BY dateCreated DESC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_lab_result` (IN `query_type` VARCHAR(20), IN `in_labno` VARCHAR(50), IN `facId` VARCHAR(50), IN `in_request_id` VARCHAR(50), IN `query_date` DATE)  NO SQL IF query_type = 'completed' THEN
	SELECT sn, sn as sort_index, specimen,code,receiptNo,booking_no, description as test, description, group_head as test_group, 
        group_head, a.department, ifnull(a.result, '') result, unit, 
        range_from, range_to, o_value, h_value, appearance,serology,culture_yielded,resistivity,sensitivity, intermediaryTo,
        a.status, a.created_by, a.created_at, a.sample_collected_by,a.report_type,
        CONCAT(b.firstname, ' ', b.lastname) AS result_by,
        result_at, reviewed_by 
        FROM lab_process 
        a JOIN users b ON a.result_by = b.username
        WHERE booking_no=in_labno AND a.facilityId=facId 
        AND b.facilityId=facId
        GROUP BY description
        ORDER BY sn asc;
ELSEIF query_type = 'uncompleted' THEN
	SELECT sn, sn as sort_index, specimen,code, receiptNo,booking_no, description as test, description, group_head as test_group, 
        group_head, department, ifnull(result,'') result, unit,  o_value, h_value,
        range_from, range_to, appearance,serology,culture_yielded,resistivity,sensitivity, intermediaryTo,
        status, created_by, created_at, sample_collected_by, result_by, result_at, reviewed_by, report_type
        FROM lab_process 
        WHERE booking_no=in_labno AND facilityId=facId
        group by description
        ORDER BY sn asc;
ELSEIF query_type = 'doctor' THEN
SELECT sn, sn as sort_index, specimen,code, receiptNo,booking_no, description as test, description, group_head as test_group, 
        group_head, department, ifnull(result,'') result, unit,  o_value, h_value,
        range_from, range_to, appearance,serology,culture_yielded,resistivity,sensitivity, intermediaryTo,
        status, created_by, created_at, date(created_at) as requested_date, sample_collected_by, result_by, result_at, reviewed_by, report_type
        FROM lab_process 
        WHERE patient_id=in_labno AND facilityId=facId
        ORDER BY sn ASC;
ELSEIF query_type = 'by_req_id' THEN
SELECT sn, sn as sort_index, specimen,code, receiptNo,booking_no, description as test, description, group_head as test_group, 
        group_head, department, ifnull(result,'') result, unit,  o_value, h_value,
        range_from, range_to, appearance,serology,culture_yielded,resistivity,sensitivity, intermediaryTo,
        status, created_by, created_at, date(created_at) as requested_date, sample_collected_by, result_by, result_at, reviewed_by, report_type
        FROM lab_process 
        WHERE patient_id=in_labno AND request_id=in_request_id AND facilityId=facId
        ORDER BY sn ASC;
ELSEIF query_type = 'by_date' THEN
SELECT sn, sn as sort_index, specimen,code, receiptNo, booking_no, description as test, description, group_head as test_group, 
        group_head, department, ifnull(result,'') result, unit,  o_value, h_value,
        range_from, range_to, appearance,serology,culture_yielded,resistivity,sensitivity, intermediaryTo,
        status, created_by, created_at, date(created_at) as requested_date, sample_collected_by, result_by, result_at, reviewed_by, report_type
        FROM lab_process 
        WHERE patient_id=in_labno AND date(created_at)=date(query_date) AND facilityId=facId
        ORDER BY sn ASC;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_lab_services_tree` (IN `facId` VARCHAR(50))  NO SQL BEGIN
	SELECT head title,subhead,price  FROM lab_setup WHERE facilityId=facId;
#SELECT id, head,subhead title  FROM lab_setup WHERE facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_list_of_drugs` (IN `in_name` VARCHAR(80), IN `in_generic_name` VARCHAR(80), IN `in_id` INT, IN `query_type` VARCHAR(20))   BEGIN
IF query_type='insert' THEN
INSERT INTO `druglist`(`name`, `generic_name`) VALUES (in_name,in_generic_name);
ELSEIF query_type='update' THEN
UPDATE druglist SET name=in_name, generic_name=in_generic_name WHERE id=in_id;
ELSEIF query_type='delete' THEN
DELETE FROM `druglist` WHERE id=in_id;
ELSE
    SELECT DISTINCT id,name as drug, generic_name FROM druglist ORDER BY created_at DESC;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_mode_payment` (IN `p_patient_id` VARCHAR(50))   BEGIN
    SELECT * FROM pending_txn 
    WHERE mode_of_payment = 'BILL' 
    AND patient_id = p_patient_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_next_lab_id` (IN `facId` VARCHAR(50))  NO SQL BEGIN
	SELECT IFNULL(max(id),0) + 1 AS labId from lab_requisition WHERE facilityId=facId; 

	COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_next_transaction_id` (IN `facId` VARCHAR(50))   BEGIN
    select max(transaction_id) + 1 from transactions WHERE facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_number_generator` (IN `in_prefix` VARCHAR(10))   SELECT code_no + 1 as code_no FROM number_generator WHERE prefix = in_prefix$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_nursing_reports` (IN `query_type` VARCHAR(10), IN `facId` VARCHAR(50))  NO SQL IF query_type = 'all' THEN
	SELECT * FROM nursing_report where facilityId=facId ORDER BY created_at DESC;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patients` (IN `_query_type` VARCHAR(50), IN `_facility_id` VARCHAR(50), IN `_patient_id` VARCHAR(10), IN `in_from` VARCHAR(50), IN `in_to` VARCHAR(50), IN `in_val` VARCHAR(200))   BEGIN
IF _query_type = 'all' THEN
SELECT CONCAT(surname, " ", firstname) AS name, address, Gender, DOB, patient_id, phoneNo, date_seen, email, id,
	   accountNo, accountType 
FROM patientrecords 
WHERE status != 'pending_registration'
  AND (firstname LIKE in_val OR surname LIKE in_val OR patient_id LIKE in_val OR accountNo LIKE in_val) 
  AND facilityId = _facility_id 
ORDER BY accountNo DESC;
    ELSEIF _patient_id IS NOT NULL THEN
        SELECT CONCAT(surname, " ", firstname) AS name, address, Gender, DOB, patient_id, email, id,
               accountNo, accountType 
        FROM patientrecords 
        WHERE status = 'registered' 
          AND facilityId = _facility_id 
          AND id = _patient_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patients_by_doctor` (IN `doc` VARCHAR(50), IN `facId` VARCHAR(50))   BEGIN
    select * from patientrecords where assigned_to = doc AND facilityId=facId ORDER BY date_assigned DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patient_acc_stmt` (IN `patientId` VARCHAR(20), IN `dateFrom` DATE, IN `dateTo` DATE, IN `facId` VARCHAR(50))   BEGIN
	SELECT t.transaction_id, t.acct,t.day,t.description, t.credit, t.debit,
       @running_total:=@running_total + t.balance AS bal, @running_total:=@running_total opening
        FROM
        ( SELECT transaction_id, acct,
          date(createdAt) as day,description,credit credit, debit debit,
          sum(credit-debit) as balance
          FROM transactions WHERE client_acct = patientId  AND date(createdAt) BETWEEN dateFrom AND dateTo AND facilityId=facId
          GROUP BY transaction_id,day,description,credit,debit,acct ) t
        JOIN (SELECT @running_total:=0) r
        ORDER BY t.transaction_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patient_drug_schedule` (IN `query_type` VARCHAR(20), IN `in_patient_id` VARCHAR(50), IN `facId` VARCHAR(50), IN `in_date` DATE)  NO SQL IF query_type = 'all_schedule' THEN
	SELECT id, allocation_id, patient_id, prescription_id, drug_name, time_stamp, date(time_stamp) time_stamp_date, status, administered_by, facilityId, served_by, stopped_by, reason, frequency FROM drug_schedule where patient_id = in_patient_id AND status != 'stop' ORDER BY time_stamp ASC, id;
ELSEIF query_type = 'by_date' THEN
	IF in_patient_id = 'all' THEN
    	SELECT a.id, b.patient_name as name, a.patient_id, b.name as bed_name, b.class_type, a.drug as drug_name, a.dosage, a.route, time_stamp, a.status, administered_by, a.facilityId, a.frequency FROM drug_schedule_view a JOIN in_patient_list b ON a.patient_id = b.patient_id where a.status != 'stop' AND date(time_stamp) = in_date AND a.facilityId=facId ORDER BY time_stamp ASC, id;
    ELSE
		SELECT * FROM drug_schedule where patient_id = in_patient_id AND status != 'stop' AND date(time_stamp) = in_date ORDER BY time_stamp ASC,id;
    END IF;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patient_list` (IN `in_facilityId` VARCHAR(255), IN `in_condition` VARCHAR(20), IN `in_query_type` VARCHAR(50))  NO SQL IF in_query_type = 'in_patients' THEN
	SELECT * FROM in_patient_list WHERE facilityId=in_facilityId ORDER BY sort_index;
ELSEIF in_query_type = 'in_patient' THEN
	SELECT * FROM in_patient_list  WHERE allocation_id=in_condition AND facilityId=in_facilityId ORDER BY sort_index;
ELSEIF in_query_type = 'in_patient_by_id' THEN
	SELECT * FROM in_patient_list  WHERE patient_id=in_condition AND facilityId=in_facilityId ORDER BY sort_index;
ELSEIF in_query_type = 'by_status' THEN
	SELECT * FROM in_patient_list  WHERE status=in_condition AND facilityId=in_facilityId ORDER BY sort_index;
    
    ELSEIF in_query_type='pending-admission' THEN 
    SELECT * FROM `patientrecords` WHERE patientStatus = 'pending-admission';
     ELSEIF in_query_type='pending-discharge' THEN 
    SELECT * FROM `patientrecords` WHERE patientStatus = 'pending-discharge';
ELSE
	SELECT id, patient_id, concat(surname, ' ', firstname) as name, dob, Gender as gender, ifnull(phoneNo,'') as phoneNo, ifnull(email, '') as email
        FROM patientrecords WHERE surname!=in_condition  AND facilityId=in_facilityId ORDER BY dateCreated DESC;
        END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patient_Record` ()   BEGIN
    SELECT firstname, 
           surname, 
           enrollee_no, 
           hmo, 
           insurance_scheme AS hmo_type, 
           date_assigned 
    FROM patientrecords
    ORDER BY date_assigned DESC
    LIMIT 50;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patient_records` (IN `facId` VARCHAR(50))   BEGIN
    select * from patientrecords WHERE facilityId=facId order by accountNo desc;
   END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patient_reg_breakdown_per_year` (IN `year` INT(4))  NO SQL SELECT COUNT(*) no_of_patients, MONTH(dateCreated) month FROM `patientrecords`  
WHERE YEAR(dateCreated) = year
GROUP BY MONTH(dateCreated)$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_patient_txn` (IN `query_type` VARCHAR(20), IN `in_patient_id` VARCHAR(50), IN `facId` VARCHAR(50))  NO SQL IF query_type = 'all' THEN
	SELECT * FROM transactions where patient_id=in_patient_id AND debit<>0 AND facilityId=facId;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_payment_mode_details` (IN `in_date_from` DATE, IN `in_date_to` DATE, IN `in_facilityid` VARCHAR(100), IN `in_payment_mode` VARCHAR(50))   BEGIN
  SELECT 
    DATE(t.transaction_date) AS transaction_date,
    t.transaction_id,
    t.patient_name,
    t.patient_id,
    GROUP_CONCAT(DISTINCT t.description SEPARATOR ', ') AS descriptions,
    t.mode_of_payment,
    SUM(t.amount) AS total_amount,
    t.cashier_id,
    COUNT(*) AS item_count
  FROM pending_txn t
  WHERE t.facilityId = in_facilityid
    AND DATE(t.transaction_date) BETWEEN in_date_from AND in_date_to
    AND t.mode_of_payment = in_payment_mode
    AND t.tx_status = 'paid'
  GROUP BY t.transaction_id, t.mode_of_payment, t.patient_id, t.patient_name, t.cashier_id, DATE(t.transaction_date)
  ORDER BY t.transaction_date DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pending_dispense` (IN `in_query_type` VARCHAR(50), IN `in_request_id` VARCHAR(50))   SELECT a.description, a.amount,b.drug,b.dosage,b.duration,b.period,b.no_of_days,b.frequency,b.drugCount,b.times_per_day,b.no_times, b.quantity,b.route,b.branch_name,b.drug_id FROM `pending_txn` a JOIN dispensary b ON a.request_id=b.request_id WHERE a.request_id=in_request_id AND a.tx_status='paid'$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pending_lab` (IN `query_type` VARCHAR(10), IN `in_dept` VARCHAR(50), IN `facId` VARCHAR(50), IN `fromDate` DATE, IN `toDate` DATE)  NO SQL BEGIN SELECT DISTINCT a.booking_no as labno, concat(b.surname, ' ', b.firstname) as name, a.department_head AS department, COUNT(distinct description) AS no_of_tests, a.patient_id, description,a.subhead,a.code FROM lab_info a JOIN patientrecords b ON a.patient_id=b.id WHERE a.status = query_type AND a.department_head=in_dept AND a.facilityId=facId AND b.facilityId=facId 
AND date(created_at) BETWEEN date(fromDate) AND date(toDate)
GROUP by labno, description,a.patient_id; END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pending_lab_request` (IN `facId` VARCHAR(50))   BEGIN 
SELECT id,concat(surname, ' ', firstname, ' ', other) fullname,DOB,gender,phoneNo,assigned_to, count(lab.patient_id) no_of_test
  FROM patientrecords JOIN lab
    ON patientrecords.id = lab.patient_id WHERE lab.status = 'request' and lab.facilityId = facId GROUP BY lab.patient_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pending_prescription_requests` (IN `facId` VARCHAR(50))   BEGIN
    #SELECT * FROM `prescriptionrequests` WHERE facilityId=facilityId ORDER BY date DESC;
SELECT id,firstname,surname,DOB,gender,phoneNo,assigned_to FROM `patientrecords` WHERE id in (SELECT patient_id from dispensary where status = "request") and facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pending_purchases` (IN `facId` VARCHAR(50))   BEGIN
    SELECT * FROM drugpurchaserecords WHERE payment_status='pending' AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pending_purchase_order` (IN `in_query_type` VARCHAR(10), IN `from_date` DATE, IN `to_date` DATE)  NO SQL IF in_query_type = 'reviewer' THEN
	SELECT a.id,po_id,date,type,vendor,client,item_name,specification,quantity_in_stock,
    	proposed_quantity,exchange_type,exchange_rate,unit_price,a.amount,
        status,insected_by,renew,po_number,total_amount+SUM( ifNull(b.amount,0)) as total_amount,grn_number,
        auditor_remark,management_remark,supplier_code,supplier_account,processed_by 
	FROM purchase_order a LEFT JOIN other_expenses b ON a.po_id=b.PONo 
    where status IN ("pending","ManagementReject", "BackToAuditor") 
    GROUP BY po_id ORDER by po_id;
    
ELSEIF in_query_type = 'auditor' THEN
	SELECT a.id,po_id,date,type,vendor,client,item_name,specification,quantity_in_stock,
    	proposed_quantity,exchange_type,exchange_rate,unit_price,a.amount,
        status,insected_by,renew,po_number,total_amount+SUM( ifNull(b.amount,0)) as total_amount,grn_number,
        auditor_remark,management_remark,supplier_code,supplier_account,processed_by 
	FROM purchase_order a LEFT JOIN other_expenses b ON a.po_id=b.PONo 
    where status IN ("BackToAuditor", "ManagementApproved","Reviewer") 
    GROUP BY po_id ORDER by po_id;
    
ELSEIF in_query_type = 'account' THEN
    SELECT a.id,po_id,date,type,vendor,client,item_name,specification,quantity_in_stock,
    	proposed_quantity,exchange_type,exchange_rate,unit_price,a.amount,
        status,insected_by,renew,po_number,total_amount+SUM( ifNull(b.amount,0)) as total_amount,grn_number,
        auditor_remark,management_remark,supplier_code,supplier_account,processed_by 
		FROM purchase_order a LEFT JOIN other_expenses b ON a.po_id=b.PONo 
    where status = "ReviewerApproved"
    	GROUP BY po_id 
    	ORDER by po_id;
ELSEIF in_query_type = 'all' THEN
	#SELECT * FROM purchase_order where facilityId=in_facilityId ORDER BY po_id DESC
    SELECT a.id,po_id,date,type,vendor,client,item_name,specification,quantity_in_stock,
    	proposed_quantity,exchange_type,exchange_rate,unit_price,a.amount,
        status,insected_by,renew,po_number,total_amount+SUM( ifNull(b.amount,0)) as total_amount,grn_number,
auditor_remark,management_remark,supplier_code,supplier_account,processed_by 
		FROM purchase_order a LEFT JOIN other_expenses b ON a.po_id=b.PONo   WHERE date(date)BETWEEN date(from_date) AND date(to_date) 
    	GROUP BY po_id 
    	ORDER by po_id;
ELSEIF in_query_type = 'management' THEN
	SELECT a.id, po_id,date,type,vendor,client,item_name, specification, quantity_in_stock, proposed_quantity,
exchange_type, exchange_rate, unit_price, a.amount, status, insected_by, renew,po_number,
total_amount+SUM( ifNull(b.amount,0)) as total_amount, grn_number, auditor_remark, management_remark, supplier_code, supplier_account, processed_by 
FROM purchase_order a LEFT JOIN other_expenses b ON a.po_id=b.PONo where status IN ("Audited","BackToManagement","ReviewerReject") GROUP BY po_id ORDER by po_id;

END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pending_tnx` (IN `in_date_from` DATE, IN `in_date_to` DATE, IN `in_type` VARCHAR(50))   BEGIN
    IF in_type = 'select' THEN
        SELECT * FROM `pending_txn` 
        WHERE tx_status = "pending" 
        AND DATE(created_at) BETWEEN in_date_from AND in_date_to;
    ELSEIF in_type = 'group' THEN
    SELECT 
 transaction_id,patient_name,patient_id,service_type,
            SUM(amount) AS total_amount, 
            COUNT(*) AS total_transactions 
        FROM `pending_txn` 
        WHERE tx_status = "pending" 
        AND DATE(created_at) BETWEEN in_date_from AND in_date_to
        GROUP BY transaction_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pending_tnx_by_id` (IN `in_txn_id` VARCHAR(50))   SELECT * FROM pending_txn WHERE transaction_id = in_txn_id$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pending_transactions` (IN `facId` VARCHAR(50))   BEGIN
    SELECT * FROM `transactions` WHERE status = "pending" AND facilityId=facId ORDER BY createdAt DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pharm_sales_summary` (IN `fac_id` VARCHAR(50), IN `dateFrom` DATE, IN `dateTo` DATE)  NO SQL SELECT  ifnull(SUM(debit), 0) totalAmount, count(debit) totalSales FROM transactions WHERE DATE(createdAt) BETWEEN date(dateFrom) AND date(dateTo) AND facilityId=fac_id AND acct='Drug Sales'$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pharm_total_stock` (IN `fac_id` VARCHAR(50))  NO SQL SELECT sum(balance) AS totalStock, sum(balance*cost_price) AS totalStockAmount, sum(dispensary_balance) as totalDisp, sum(dispensary_balance*(cost_price+markUp)) as totalDispAmount FROM drugpurchaserecords WHERE facilityId = fac_id$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_prescribed_drugs` (IN `query_type` VARCHAR(50), IN `in_patient_id` VARCHAR(50), IN `facId` VARCHAR(50))  NO SQL IF query_type = 'pending' THEN
	SELECT route,drug,dosage,patient_id,id as prescription_id, created_at,duration,period,frequency, startTime,times_per_day,end_date FROM dispensary WHERE patient_id=in_patient_id AND schedule_status='pending' AND decision='admit' AND facilityId = facId;
	#SELECT route,drug,dosage,patient_id,a.id as prescription_id, created_at,duration,period,frequency, b.time_start, b.interval_, b.interval_uom FROM dispensary a JOIN drug_frequency b on a.frequency=b.description WHERE patient_id=in_patient_id AND schedule_status='pending' AND decision='admit' AND facilityId = facId;
ELSEIF query_type ='current' THEN
	SELECT created_at, concat(route,' ', drug,' ',dosage, ' ', frequency, ' for ', duration, ' ', period) as medication, duration, period, id, created_at FROM dispensary WHERE id in (SELECT prescription_id FROM drug_schedule WHERE status = 'scheduled') AND patient_id=in_patient_id AND facilityId = facId;
ELSEIF query_type = 'by_req_id' THEN
	SELECT drug,dosage,patient_id,id, created_at,duration,period,frequency, route FROM dispensary WHERE request_id=in_patient_id AND facilityId = facId;
ELSEIF query_type = 'out-patient' THEN
	SELECT request_id, route,drug,dosage,patient_id,id as prescription_id, created_at,duration,period,frequency, startTime FROM dispensary WHERE patient_id=in_patient_id AND schedule_status='pending' AND decision='out-patient' AND facilityId = facId;
ELSEIF query_type = 'out-patient-list' THEN
	SELECT concat(b.firstname,' ',b.surname,' (',b.id,')') as patient_info, route,drug,dosage,a.patient_id,a.id as prescription_id,request_id, created_at,duration,period,frequency, startTime FROM dispensary a JOIN patientrecords b ON a.patient_id = b.id WHERE schedule_status='pending' AND date(a.end_date) >= date(now()) AND decision='out-patien' AND a.facilityId = facId;
ELSEIF query_type = 'med-report' THEN
	SELECT * FROM medication_report WHERE patient_id=in_patient_id ORDER BY time_stamp DESC;
ELSEIF query_type = 'close outpatient prescription' THEN
	UPDATE dispensary SET schedule_status='ended' WHERE request_id=in_patient_id AND facilityId=facId;

    
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_purchase_records` (IN `facId` VARCHAR(50))   BEGIN
    SELECT a.drug,a.cost_price,a.balance as quantity, quantity as quantity_bought ,a.expiry_date,a.created_at,b.supplier_name as supplier 
    FROM drugpurchaserecords a JOIN suppliersinfo b ON a.supplier=b.id WHERE a.facilityId=facId ORDER BY created_at DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_receipt_date_sn` (IN `dateAppend` VARCHAR(30), IN `facId` VARCHAR(50))   BEGIN
    select receiptDateSN like dateAppend from transaction WHERE facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_reports` (IN `fromDate` VARCHAR(30), IN `toDate` VARCHAR(30), IN `facId` VARCHAR(50))   BEGIN
    SELECT * FROM `transactions` WHERE createdAt BETWEEN fromDate AND toDate AND facilityId = facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_report_by_type` (IN `type` VARCHAR(50), IN `facId` VARCHAR(50), IN `fromDate` DATE, IN `toDate` DATE)  NO SQL BEGIN
	IF type = 'revenue' THEN
    	-- SELECT transaction_id, transaction_date, description, acct, credit, receiptDateSN, modeOfPayment,client_acct, concat(b.surname, ' ', b.firstname) as patient_id FROM `transactions` a JOIN patientrecords b ON (a.patient_id = b.id AND a.facilityId=b.facilityId) where credit <> 0 AND acct like '20%'  AND a.facilityId=facId AND date(transaction_date) BETWEEN date(fromDate) AND date(toDate);
        -- yesterday
-- SELECT head AS acct,patient_id As client_acct, amount AS credit,description,mode_of_payment AS modeOfPayment, patient_name AS patient_id,transaction_id AS receiptDateSN,transaction_date,id AS transaction_id FROM pending_txn WHERE date(transaction_date) BETWEEN date(fromDate) AND date(toDate) AND amount > 0;

-- this morning 
SELECT 
    head AS acct, 
    patient_id AS client_acct, 
    amount AS credit, 
    description, 
    mode_of_payment AS modeOfPayment, 
    patient_name AS patient_id, 
    transaction_id AS receiptDateSN, 
    transaction_date, 
    id AS transaction_id 
FROM pending_txn 
WHERE date(transaction_date) BETWEEN date(fromDate) AND date(toDate) 
    AND amount > 0 
    AND facilityId =facId;

    ELSEIF type = 'expenses' THEN
    	SELECT transaction_id, transaction_date, description, acct, debit, receiptDateSN, modeOfPayment,client_acct FROM `transactions` where debit <> 0 AND acct like '30%' AND facilityId=facId AND date(transaction_date) BETWEEN date(fromDate) AND date(toDate);
        
    ELSEIF type = 'trialbalance' THEN
    	SELECT a.head AS head,a.subhead AS subhead,a.des AS des,a.acct AS acct,b.description AS description,(sum(a.debit) - sum(a.credit)) AS debit,(sum(a.credit) - sum(a.debit)) AS credit,a.transaction_date AS date,a.facilityId AS facilityId 
		FROM (test1 a JOIN account b ON ((a.subhead = b.head))) 
    	WHERE a.transaction_date BETWEEN date(fromDate) and date(toDate)
    	GROUP BY head,a.subhead,a.head,a.des,a.acct,(b.description <> 0);
    
    ELSEIF type = 'profitloss' THEN
    	SELECT a.head AS head,a.subhead AS subhead,a.des AS des,a.acct AS acct,b.description AS description,(sum(a.debit) - sum(a.credit)) AS debit,(sum(a.credit) - sum(a.debit)) AS credit,a.transaction_date AS date,a.facilityId AS facilityId 
		FROM (test1 a JOIN account b ON ((a.subhead = b.head))) 
    	WHERE a.subhead like '200%' OR a.subhead like '300%' AND a.transaction_date BETWEEN date(fromDate) and date(toDate)
    	GROUP BY head,a.subhead,a.head,a.des,a.acct,(b.description <> 0);
    	
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_request_no` (IN `in_facilityId` VARCHAR(50))   SELECT ifnull(max(request_id), 0) + 1 as request_id FROM lab_requisition WHERE facilityId=in_facilityId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_rev_acc_heads` (IN `facId` VARCHAR(50))   BEGIN
    SELECT head as title, subhead, description, price FROM account WHERE subhead = '20000' and facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_roles` (IN `facId` VARCHAR(50))   BEGIN
    select distinct role from users WHERE facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_test_by_patient` (IN `patientId` VARCHAR(20), IN `facId` VARCHAR(50))  NO SQL SELECT * from lab WHERE patient_id = patientId AND facilityId=facId AND status in ('request')$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_top_5_popular_drugs` (IN `fac_id` VARCHAR(50), IN `today` DATE)  NO SQL SELECT drug, COUNT(*) count FROM dispensary WHERE facilityId=fac_id AND DATE(created_at) = today GROUP BY drug ORDER BY count DESC LIMIT 5$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_total_sales` (IN `user` VARCHAR(50), IN `date` DATE, IN `facId` VARCHAR(50))   BEGIN
    SELECT SUM(credited-debited) as totalSales, date(createdAt) as date from transactions WHERE enteredBy = user and date(createdAt) = date AND facilityId=facId GROUP by date(createdAt);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_unassigned` (IN `facId` VARCHAR(50))   BEGIN
    select title,surname,firstname,other, concat(firstname,' ',surname,' ',other) fullname,Gender,age,maritalstatus,DOB,dateCreated,phoneNo,email,state,lga,occupation,address,kinName,kinRelationship,kinPhone,kinEmail,kinAddress,accountNo,beneficiaryNo,balance,id,enteredBy,patientStatus,assigned_to,createdAt from patientrecords WHERE facilityId=facId order by accountNo desc;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_users` (IN `facId` VARCHAR(50))   BEGIN
    -- Get all users for the facility except developers
    SELECT * FROM users 
    WHERE facilityId = facId 
    AND LOWER(role) != 'developer'
    ORDER BY createdAt DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_user_by_id` (IN `id` VARCHAR(10), IN `facId` VARCHAR(50))   BEGIN
    select * from patientrecords where id=id AND facilityId=facId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `good_received` (IN `in_status` VARCHAR(50), IN `in_id` INT(50))  NO SQL BEGIN

if in_status="unfinished purchase" 
THEN
select a.item_name,a.price,a.type,a.item_category,a.propose_quantity,a.po_id,a.exchange_rate,sum(b.qty_in) as qty_in, (a.propose_quantity - (select sum(b.qty_in) from store a where a.po_no=in_id GROUP by po_no )) as quantity,expired_status from purchase_order_list a join store b on a.po_id=b.po_no AND a.po_id =in_id GROUP by a.item_name,a.price,a.type, a.propose_quantity,a.po_id,a.exchange_rate;

ELSEIF in_status ="new order" THEN
SELECT id,item_name, price,propose_quantity ,type,item_category, po_id,identifier,exchange_rate,date,received_qty, expired_status FROM purchase_order_list WHERE po_id=in_id AND status="new order";
end if;
End$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `good_transfer` (IN `in_version_id` VARCHAR(100), IN `in_qty_in` INT(6), IN `in_expiring_date` DATE, IN `in_selling_price` FLOAT(10), IN `in_location_from` VARCHAR(100), IN `in_location_to` VARCHAR(100), IN `in_facilityId` VARCHAR(100), IN `in_item_name` VARCHAR(100), IN `in_receive_date` DATE, IN `in_unit_price` FLOAT(10), IN `in_mark_up` FLOAT(10), IN `supplyName` VARCHAR(50), IN `supply_code` VARCHAR(50))   BEGIN
DECLARE trn int;
declare item_code_data,description_data,price_data,balance_data, facilityId_data varchar(50);
declare expiry_date_data date;
declare new_item_balance,transfers_balance,new_transfers_balance int;

declare item_code_data1,description_data1,price_data1,balance_data1, facilityId_data1 varchar(50);
declare expiry_date_data1 date;
declare new_item_balance1 int;

SELECT max(ifNull(code_no,0)+1)  INTO trn from number_generator WHERE prefix='trn';

SELECT item_code,drug_name,price,balance, facilityId, expiry_date 
into item_code_data1,description_data1,price_data1,balance_data1, facilityId_data1,expiry_date_data1 
FROM `pharm_store` where drug_name=in_item_name and price=in_unit_price and expiry_date=in_expiring_date and store=in_location_from; 

set new_item_balance1=balance_data1-in_qty_in;

update `pharm_store`set balance=new_item_balance1  where drug_name=description_data1 and price=price_data1 and expiry_date=expiry_date_data1  and store=in_location_from; 

SELECT balance INTO transfers_balance from pharm_store where drug_name=description_data1 and price=price_data1 and expiry_date=expiry_date_data1  and store = in_location_to;

IF transfers_balance is null then 
INSERT INTO `pharm_store`(`balance`, `drug_name`, `price`, `facilityId`, `item_id`, `expiry_date`, `store`, `selling_price`, `supplier_name`, `supplier_code`, `insert_date`, `store_location`) VALUES (in_qty_in,in_item_name,in_unit_price,in_facilityId,in_version_id,in_expiring_date,in_location_to,in_selling_price,supplyName,supply_code,now(),in_location_from);

INSERT INTO pharm_store_entries(receive_date,drug_name,expiry_date,`transfer_from`,qty_out,qty_in,`transfer_to`,unit_price,selling_price,mark_up,branch_name,facilityId,version_id,supplier_code,supplier_name,sales_type)
VALUES(now(),in_item_name,in_expiring_date,in_location_from,in_qty_in, 0,in_location_to,in_unit_price,in_selling_price,in_mark_up,in_location_from,in_facilityId,in_location_from,supply_code,supplyName,concat("Transfer to ", in_location_to));

INSERT INTO pharm_store_entries(receive_date,drug_name,expiry_date,`transfer_from`,qty_out,qty_in,`transfer_to`,unit_price,selling_price,mark_up,branch_name,facilityId,version_id,supplier_code,supplier_name,sales_type)
VALUES(now(),in_item_name,in_expiring_date,in_location_from,0 ,in_qty_in,in_location_to,in_unit_price,in_selling_price,in_mark_up,in_location_to,in_facilityId,in_location_to,supply_code,supplyName,concat("Transfer to ", in_location_to));


ELSE
SET new_transfers_balance = transfers_balance + in_qty_in;
UPDATE pharm_store SET balance = new_transfers_balance  where drug_name=description_data1 and price=price_data1 and expiry_date=expiry_date_data1  and store = in_location_to;


INSERT INTO pharm_store_entries(receive_date,drug_name,expiry_date,`transfer_from`,qty_out,qty_in,`transfer_to`,unit_price,selling_price,mark_up,branch_name,facilityId,version_id,supplier_code,supplier_name,sales_type,branch_name)
VALUES(now(),in_item_name,in_expiring_date,in_location_from,in_qty_in, 0,in_location_to,in_unit_price,in_selling_price,in_mark_up,in_location_from,in_facilityId,in_location_from,supply_code,supplyName,concat("Transfer to ", in_location_to));

INSERT INTO pharm_store_entries(receive_date,drug_name,expiry_date,`transfer_from`,qty_out,qty_in,`transfer_to`,unit_price,selling_price,mark_up,branch_name,facilityId,version_id,supplier_code,supplier_name,sales_type)
VALUES(now(),in_item_name,in_expiring_date,in_location_from,0 ,in_qty_in,in_location_to,in_unit_price,in_selling_price,in_mark_up,in_location_to,in_facilityId,in_location_to,supply_code,supplyName,concat("Transfer to ", in_location_to));
	
end IF;


#INSERT INTO `sale_department`(`version_id`, `item_name`, `qty_in`, `qty_out`, `expiring_date`, `selling_price`, `location_from`, `location_to`,`facilityId`,supplier_name,supplier_code)
#VALUES (in_version_id,in_item_name,0,new_item_balance1,expiry_date_data1,in_selling_price,in_location_from,in_location_to,in_facilityId,supplyName,supply_code);

#SELECT item_code,description,price,ifnull(balance,0), facilityId, expiry_date 
#into item_code_data,description_data,price_data,balance_data, facilityId_data,expiry_date_data 
#FROM `item_description` where description=in_item_name and price=in_selling_price and expiry_date=in_expiring_date and store=in_location_from; 

#set new_item_balance=balance_data+ifnull(in_qty_in,0);

#insert into store(description,price,balance, facilityId, expiry_date,store )
#values (in_item_name,in_selling_price,new_item_balance, in_facilityId,in_expiring_date ,in_location_from) on duplicate key update balance=new_item_balance;

#INSERT INTO `sale_department`(`version_id`, `item_name`, `qty_in`, `qty_out`, `expiring_date`, `selling_price`, `location_from`, `location_to`, `facilityId`,supplier_name,supplier_code,item_status,trn_number)
#VALUES (concat(in_version_id,'-1'),in_item_name,in_qty_in,0,in_expiring_date,in_selling_price,in_location_from,in_location_to,in_facilityId,supplyName,supply_code,"Pending",trn);
call update_number_generator('trn',trn);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `good_transfer_report` (IN `date_from` VARCHAR(30), IN `date_to` VARCHAR(30), IN `facId` VARCHAR(60))   SELECT * FROM `pharm_store_entries` WHERE transfer_to !='' AND transfer_to !='pos' AND transfer_from !='Purchase order' AND qty_in > 0 AND date(inserted_time) BETWEEN date_from AND date_to and facilityId=facId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `group_service` (IN `in_head` VARCHAR(30), IN `in_subhead` VARCHAR(30), IN `in_descr` VARCHAR(90), IN `facId` VARCHAR(56), IN `query_type` VARCHAR(30), IN `in_price` FLOAT, IN `in_qty` FLOAT)   BEGIN
IF query_type = 'insert' THEN
INSERT INTO `group_service`(`head`, `subhead`, `description`, `facilityId`,price,quantity) VALUES (in_head,in_subhead,in_descr,facId,in_price,in_qty);
ELSEIF query_type = 'select' THEN
SELECT DISTINCT description,SUM(price)as price FROM group_service WHERE facilityId=facId GROUP BY description;
ELSEIF query_type = 'group_list' THEN
SELECT a.head, a.subhead, a.description, a.price, g.quantity FROM account a JOIN group_service g ON a.head = g.head WHERE g.description = in_descr AND g.facilityId = facId;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `hmo_registration` (IN `_HMO_name` VARCHAR(30))   BEGIN
    INSERT INTO hmo_registration_table(HMO_name) VALUE(_HMO_name);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `icd` ()   BEGIN
    SELECT _id, code, name, description 
    FROM icd_code 
    ORDER BY name ASC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `lab_summary` (IN `in_query_type` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `in_fromdate` DATE, IN `in_todate` DATE, IN `in_report_by` VARCHAR(50))  NO SQL BEGIN
    -- Patient Income Report
    IF in_query_type = 'patient income' THEN
        IF in_report_by = 'all' THEN
            SELECT 
                patient_id, 
                patient_name AS fullname, 
                SUM(amount) AS total_income, 
                DATE(COALESCE(transaction_date, created_at)) AS transaction_date
            FROM pending_txn 
            WHERE tx_status = 'paid' 
              AND facilityId = in_facId
              AND DATE(COALESCE(transaction_date, created_at)) BETWEEN in_fromdate AND in_todate
            GROUP BY patient_id, patient_name, transaction_date
            ORDER BY transaction_date DESC;
        ELSE
            SELECT 
                patient_id, 
                patient_name AS fullname, 
                SUM(amount) AS total_income, 
                DATE(COALESCE(transaction_date, created_at)) AS transaction_date
            FROM pending_txn 
            WHERE tx_status = 'paid' 
              AND facilityId = in_facId
              AND cashier_id = in_report_by
              AND DATE(COALESCE(transaction_date, created_at)) BETWEEN in_fromdate AND in_todate
            GROUP BY patient_id, patient_name, transaction_date
            ORDER BY transaction_date DESC;
        END IF;

    -- Daily Total Report
  ELSEIF in_query_type = 'daily total' THEN
    IF in_report_by = 'all' THEN
        SELECT 
            DATE(COALESCE(transaction_date, created_at)) AS transaction_date, 
            mode_of_payment, 
            SUM(amount) AS total_amount 
        FROM pending_txn 
        WHERE tx_status = 'paid' 
          AND facilityId = in_facId
          AND DATE(COALESCE(transaction_date, created_at)) BETWEEN in_fromdate AND in_todate
        GROUP BY DATE(COALESCE(transaction_date, created_at)), mode_of_payment
        ORDER BY transaction_date DESC;
    ELSE 
        SELECT 
            DATE(COALESCE(transaction_date, created_at)) AS transaction_date, 
            mode_of_payment, 
            SUM(amount) AS total_amount 
        FROM pending_txn 
        WHERE tx_status = 'paid' 
          AND facilityId = in_facId
          AND cashier_id = in_report_by
          AND DATE(COALESCE(transaction_date, created_at)) BETWEEN in_fromdate AND in_todate
        GROUP BY DATE(COALESCE(transaction_date, created_at)), mode_of_payment
        ORDER BY transaction_date DESC;
    END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `lab_summaryb4` (IN `in_query_type` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `in_fromdate` DATE, IN `in_todate` DATE, IN `in_report_by` VARCHAR(50))  NO SQL BEGIN
	IF in_query_type = 'patient income' THEN
    	if in_report_by = 'all' THEN
    	SELECT concat(b.firstname,' ',b.surname) as fullname, sum(debit)as debit, sum(credit) as credit, sum(debit - credit) as balance, a.createdAt FROM transactions a JOIN patientrecords b ON a.patient_id=b.id AND a.facilityId=b.facilityId WHERE a.facilityId=in_facId AND date(a.createdAt) between in_fromdate AND in_todate GROUP BY fullname, date(a.createdAt) ORDER BY createdAt DESC;
        ELSE
        	SELECT concat(b.firstname,' ',b.surname) as fullname, sum(debit) as debit, sum(credit) as credit, sum(debit - credit) as balance, a.createdAt FROM transactions a JOIN patientrecords b ON a.patient_id=b.id AND a.facilityId=b.facilityId WHERE a.facilityId=in_facId AND a.enteredBy=in_report_by AND date(a.createdAt) between in_fromdate AND in_todate GROUP BY fullname, date(a.createdAt) ORDER BY createdAt DESC;
            END IF;
        
    ELSEIF in_query_type = 'daily total' THEN
    	IF in_report_by = 'all' THEN
    	SELECT date(createdAt) as createdAt, Acct_source, sum(debit) as amount, acct FROM trial_balance where facilityId=in_facId AND acct in (400021,400022,400023,400024,400025) AND date(createdAt) between in_fromdate AND in_todate GROUP BY Acct_source, acct, date(createdAt) ORDER BY createdAt desc;
        ELSE 
        	SELECT date(createdAt) as createdAt, Acct_source, sum(debit) as amount, acct FROM trial_balance where facilityId=in_facId AND enteredBy=in_report_by AND acct in (400021,400022,400023,400024,400025) AND date(createdAt) between in_fromdate AND in_todate GROUP BY Acct_source, acct, date(createdAt) ORDER BY createdAt desc;
            END IF;
        
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `lab_summarynew` (IN `in_query_type` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `in_fromdate` DATE, IN `in_todate` DATE, IN `in_report_by` VARCHAR(50))  NO SQL BEGIN
    -- Patient Income Report
    IF in_query_type = 'patient income' THEN
        IF in_report_by = 'all' THEN
            SELECT 
                patient_id, 
                patient_name AS fullname, 
                SUM(amount) AS total_income, 
                DATE(COALESCE(transaction_date)) AS transaction_date
            FROM pending_txn 
            WHERE tx_status = 'paid' 
              AND DATE(COALESCE(transaction_date)) BETWEEN in_fromdate AND in_todate
            GROUP BY patient_id, patient_name,  DATE(COALESCE(transaction_date))
            ORDER BY transaction_date DESC;
        ELSE
            SELECT 
                patient_id, 
                patient_name AS fullname, 
                SUM(amount) AS total_income, 
                DATE(COALESCE(transaction_date)) AS transaction_date
            FROM pending_txn 
            WHERE tx_status = 'paid' 
              AND cashier_id = in_report_by
              AND DATE(COALESCE(transaction_date)) BETWEEN in_fromdate AND in_todate
            GROUP BY patient_id, patient_name, transaction_date
            ORDER BY transaction_date DESC;
        END IF;

    -- Daily Total Report
    ELSEIF in_query_type = 'daily total' THEN
        IF in_report_by = 'all' THEN
            SELECT 
                DATE(COALESCE(transaction_date, created_at)) AS transaction_date, 
                mode_of_payment, 
                SUM(amount) AS total_amount 
            FROM pending_txn 
            WHERE tx_status = 'paid' 
              AND DATE(COALESCE(transaction_date, created_at)) BETWEEN in_fromdate AND in_todate
            GROUP BY mode_of_payment,  DATE(COALESCE(transaction_date, created_at))
            ORDER BY transaction_date DESC;
        ELSE 
            SELECT 
                DATE(COALESCE(transaction_date, created_at)) AS transaction_date, 
                mode_of_payment, 
                SUM(amount) AS total_amount 
            FROM pending_txn 
            WHERE tx_status = 'paid' 
              AND cashier_id = in_report_by
              AND DATE(COALESCE(transaction_date, created_at)) BETWEEN in_fromdate AND in_todate
            GROUP BY mode_of_payment, transaction_date
            ORDER BY transaction_date DESC;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ldl_formula` (IN `TC` INT, IN `HDL` INT, IN `TG` INT, OUT `LDL` INT)  NO SQL BEGIN

SELECT TC - HDL - (TG/2.2) AS LDL;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `move_items_to_dispensary` (IN `drug_name` VARCHAR(100), IN `cost` INT, IN `expiry` VARCHAR(20), IN `d_code` VARCHAR(50), IN `d_price` INT, IN `unit` INT, IN `in_qty` INT, IN `userId` VARCHAR(50), IN `generic` VARCHAR(100), IN `facId` VARCHAR(50), IN `supplierId` VARCHAR(50), IN `itemSource` VARCHAR(10), IN `mark_up` INT, IN `in_receiptno` VARCHAR(50), IN `in_shift` VARCHAR(20))   BEGIN
  DECLARE store_qty int;
  DECLARE dispensary_qty int;
  DECLARE drug_id INT;
  
  SELECT id INTO drug_id FROM druglist WHERE name=drug_name AND generic_name=generic;
  IF drug_id IS null THEN
  INSERT INTO druglist (name,generic_name) VALUES (drug_name,generic);
  end IF;
  
  IF itemSource = 'store' THEN
  select balance, dispensary_balance into store_qty, dispensary_qty FROM drugpurchaserecords WHERE drug=drug_name AND cost_price=cost AND expiry_date=expiry AND supplier=supplierId;
  
  UPDATE drugpurchaserecords SET balance = store_qty - in_qty, dispensary_balance = dispensary_qty + in_qty WHERE drug=drug_name AND cost_price=cost AND expiry_date=expiry AND supplier=supplierId;

  INSERT INTO drugs(drug_code,drug,expiry_date,price,
        unit_of_issue,
        qty_in,
        qty_out,
        source,
        created_by,
        genericName,
        facilityId,markup,receipt_no,shift)
        values (d_code,drug_name,expiry,cost,unit,0,in_qty,'purchases',userId,generic,facId,mark_up,in_receiptno,in_shift);
        
   INSERT INTO drugs(drug_code,drug,expiry_date,price,
        unit_of_issue,
        qty_in,
        qty_out,
        source,
        created_by,
        genericName,
        facilityId,markup,receipt_no,shift)
        values (d_code,drug_name,expiry,cost,unit,in_qty,0,'dispensary',userId,generic,facId,mark_up,in_receiptno,in_shift);
        
        ELSE
        select dispensary_balance into dispensary_qty FROM drugpurchaserecords WHERE drug=drug_name AND cost_price=cost AND expiry_date=expiry AND supplier=supplierId;
        
        IF dispensary_qty IS NOT null THEN
  
  UPDATE drugpurchaserecords SET balance=dispensary_qty + in_qty, dispensary_balance = dispensary_qty + in_qty WHERE drug=drug_name AND cost_price=cost AND expiry_date=expiry AND supplier=supplierId;
  
   INSERT INTO drugs(drug_code,drug,expiry_date,price,
        unit_of_issue,
        qty_in,
        qty_out,
        source,
        created_by,
        genericName,
        facilityId,markup,supplier,receipt_no,shift)
        values (d_code,drug_name,expiry,cost,unit,0,in_qty,'purchases',
                userId,generic,facId,mark_up,supplierId,in_receiptno,in_shift);
        
   INSERT INTO drugs(drug_code,drug,expiry_date,price,
        unit_of_issue,
        qty_in,
        qty_out,
        source,
        created_by,
        genericName,
        facilityId,markup,supplier,receipt_no,shift)
        values (d_code,drug_name,expiry,cost,unit,in_qty,0,'dispensary',
                userId,generic,facId,mark_up,supplierId,in_receiptno, in_shift);
  
  else 
  
        INSERT into drugpurchaserecords (drug_code,drug,generic_name,unit_of_issue,cost_price,markUp,quantity, by_whom,supplier,receipt_no,payment_status,expiry_date,dispensary_balance,facilityId) VALUES (d_code,drug_name,generic,unit,cost,mark_up,in_qty,userId,supplierId,'0','paid',expiry,in_qty,facId);
        
        INSERT INTO drugs(drug_code,drug,expiry_date,price,
        unit_of_issue,
        qty_in,
        qty_out,
        source,
        created_by,
        genericName,
        facilityId,markup,supplier,receipt_no,shift)
        values (d_code,drug_name,expiry,cost,unit,0,in_qty,'purchases',userId,
                generic,facId,mark_up,supplierId,in_receiptno,in_shift);
        
   INSERT INTO drugs(drug_code,drug,expiry_date,price,
        unit_of_issue,
        qty_in,
        qty_out,
        source,
        created_by,
        genericName,
        facilityId,markup,supplier,receipt_no,shift)
        values (d_code,drug_name,expiry,cost,unit,in_qty,0,'dispensary',userId,
                generic,facId,mark_up,supplierId,in_receiptno,in_shift);
        
        END IF;
        end if;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `new_acc_head` (IN `in_head` VARCHAR(100), IN `in_subhead` VARCHAR(100), IN `description` VARCHAR(200), IN `balance` INT(11), IN `facId` VARCHAR(50), IN `in_price` INT, IN `in_query_type` VARCHAR(50))   BEGIN
	IF in_query_type = 'next child' THEN
    	SELECT ifnull(MAX(head)+ 1, concat(in_subhead,'1'))  as next_code FROM account WHERE subhead=in_subhead AND facilityId=facId;
    ELSE
    	INSERT INTO account(head, subhead, description, balance, facilityId,price) VALUES (description,in_subhead,in_head,balance, facId,in_price);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `new_drug_sale` (IN `drug_name` VARCHAR(100), IN `cost` INT, IN `expiry` VARCHAR(20), IN `genericName` VARCHAR(100), IN `unit` VARCHAR(50), IN `quantity_in` INT, IN `userId` VARCHAR(50), IN `supplierId` VARCHAR(50), IN `descr` VARCHAR(100), IN `source_head` VARCHAR(100), IN `amt` INT, IN `receiptsn` VARCHAR(50), IN `receiptno` VARCHAR(50), IN `payment_mode` VARCHAR(50), IN `dest_head` VARCHAR(100), IN `facId` VARCHAR(50), IN `d_code` VARCHAR(50), IN `selling_price` INT, IN `accNo` VARCHAR(50), IN `transactionType` VARCHAR(20), IN `txn_date` DATE)   BEGIN 
  DECLARE balance_dispensary int;
  DECLARE acc_balance int;
  
  IF transactionType='insta' THEN
  
  SELECT dispensary_balance INTO balance_dispensary FROM drugpurchaserecords WHERE drug=drug_name AND cost_price=cost AND expiry_date=expiry ;
  
  UPDATE drugpurchaserecords set dispensary_balance = balance_dispensary - quantity_in WHERE drug=drug_name AND cost_price=cost AND expiry_date=expiry;
  
  INSERT INTO drugs (drug_code,drug,expiry_date,price,unit_of_issue,qty_in,qty_out,source,supplier,receipt_no,created_by,genericName,facilityId,client_acct) VALUES (d_code,drug_name,expiry,selling_price,unit,quantity_in,0,'sold_items',supplierId,receiptsn,userId,genericName,facId,accNo);
  
  INSERT INTO drugs (drug_code,drug,expiry_date,price,unit_of_issue,qty_in,qty_out,source,supplier,receipt_no,created_by,genericName,facilityId,client_acct) VALUES (d_code,drug_name,expiry,selling_price,unit,0,quantity_in,'dispensary',supplierId,receiptsn,userId,genericName,facId,accNo);


 -- INSERT INTO transactions (description, acct, debit, credit, enteredBy, receiptDateSN, receiptNo,
 --                           modeOfPayment,facilityId,client_acct) 
 --       VALUES (descr,source_head,0,amt,userId,receiptsn,receiptno,payment_mode,facId,accNo);
 -- INSERT INTO transactions (description, acct, debit, credit, enteredBy, receiptDateSN, receiptNo, 
 --                           modeOfPayment,facilityId,client_acct) 
 --     VALUES (descr,dest_head,amt,0,userId,receiptsn,receiptno,payment_mode,facId,accNo);
      
     ELSEIF transactionType='deposit' THEN
      
      SELECT dispensary_balance INTO balance_dispensary FROM drugpurchaserecords WHERE drug=drug_name AND cost_price=cost AND expiry_date=expiry;
  
  UPDATE drugpurchaserecords set dispensary_balance = balance_dispensary - quantity_in WHERE drug=drug_name AND cost_price=cost AND expiry_date=expiry;
  
 INSERT INTO drugs (drug_code,drug,expiry_date,price,unit_of_issue,qty_in,qty_out,source,supplier,receipt_no,created_by,genericName,facilityId,client_acct) VALUES (d_code,drug_name,expiry,selling_price,unit,quantity_in,0,'sold_items',supplierId,receiptsn,userId,genericName,facId,accNo);
  
  INSERT INTO drugs (drug_code,drug,expiry_date,price,unit_of_issue,qty_in,qty_out,source,supplier,receipt_no,created_by,genericName,facilityId,client_acct) VALUES (d_code,drug_name,expiry,selling_price,unit,0,quantity_in,'dispensary',supplierId,receiptsn,userId,genericName,facId,accNo);


 -- INSERT INTO transactions (description, acct, debit, credit, enteredBy, receiptDateSN, receiptNo,
   --                         modeOfPayment,facilityId,client_acct) 
     --   VALUES (descr,source_head,0,amt,userId,receiptsn,receiptno,payment_mode,facId,accNo);
 -- INSERT INTO transactions (description, acct, debit, credit, enteredBy, receiptDateSN, receiptNo, 
   --                         modeOfPayment,facilityId,client_acct) 
     -- VALUES (descr,dest_head,amt,0,userId,receiptsn,receiptno,payment_mode,facId,accNo);
      
	--  SELECT balance into acc_balance from patientfileno WHERE accountNo=accNo AND facilityId=facId;
	--  UPDATE patientfileno SET balance = acc_balance - amt WHERE accountNo = accNo AND facilityId=facId;
   END IF;
COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `new_expense` (IN `facId` VARCHAR(50), IN `descr` VARCHAR(100), IN `source_head` VARCHAR(100), IN `dest_head` VARCHAR(100), IN `receiptsn` VARCHAR(50), IN `receiptno` VARCHAR(50), IN `payment_mode` VARCHAR(50), IN `userId` VARCHAR(50), IN `amt` INT, IN `collected` VARCHAR(100), IN `in_date` DATETIME, IN `in_txn_date` DATE)   BEGIN 
    INSERT INTO transactions (description, acct, debit, credit, enteredBy, receiptDateSN, receiptNo, modeOfPayment,facilityId,client_acct,createdAt,transaction_date) 
        VALUES (descr,source_head,0,amt,userId,receiptsn,receiptno,payment_mode,facId,collected,in_date,in_txn_date);
    INSERT INTO transactions (description, acct, debit, credit, enteredBy, receiptDateSN, receiptNo, modeOfPayment,facilityId,client_acct,createdAt,transaction_date) 
      VALUES (descr,dest_head,amt,0,userId,receiptsn,receiptno,payment_mode,facId,collected,in_date,in_txn_date);
      
   #    INSERT INTO transactions (description, acct, debit, credit, enteredBy, receiptDateSN, receiptNo, modeOfPayment,facilityId,client_acct,createdAt) 
    #  VALUES (descr,'500011',amt,0,userId,receiptsn,receiptno,payment_mode,facId,collected,in_date);
    
    COMMIT;
  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `new_nursing_report` (IN `query_type` VARCHAR(10), IN `in_facId` VARCHAR(50), IN `in_user` VARCHAR(50), IN `in_report` VARCHAR(1000), IN `in_created_at` TIMESTAMP, IN `in_id` INT)  NO SQL IF query_type = 'new' THEN
	INSERT into nursing_report (created_by,created_at,report,facilityId) VALUES (in_user,in_created_at,in_report,in_facId);
    ELSEIF query_type = 'update' THEN
    UPDATE nursing_report SET report=in_report WHERE id=in_id AND created_by=in_user AND facilityId=in_facId;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `new_prescription` (IN `in_drug` VARCHAR(100), IN `in_dosage` VARCHAR(50), IN `in_period` VARCHAR(20), IN `in_duration` VARCHAR(20), IN `in_frequency` VARCHAR(20), IN `in_patient_id` VARCHAR(50), IN `in_prescribed_by` VARCHAR(50), IN `in_facilityId` VARCHAR(50), IN `in_status` VARCHAR(50), IN `in_request_id` VARCHAR(50), IN `in_route` VARCHAR(20), IN `in_additionalInfo` VARCHAR(200), IN `in_decision` VARCHAR(20), IN `in_startTime` DATETIME, IN `in_times_per_day` INT, IN `in_id` VARCHAR(50), IN `in_end_date` DATETIME, IN `in_no_of_days` INT, IN `in_drug_count` INT, IN `in_no_times` INT, IN `in_drug_id` VARCHAR(100))  NO SQL insert into dispensary(drug_id,drug,dosage,period,duration, frequency, patient_id, prescribed_by, facilityId, status, request_id, route, additionalInfo, decision, startTime, times_per_day, id, end_date, no_of_days, drugCount, no_times) VALUES (in_drug_id,in_drug,in_dosage,in_period,in_duration, in_frequency, in_patient_id, in_prescribed_by, in_facilityId, in_status, in_request_id, in_route, in_additionalInfo, in_decision, in_startTime, in_times_per_day, in_id, in_end_date, in_no_of_days, in_drug_count, in_no_times)$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `nursing_note` (IN `in_report` VARCHAR(150), IN `in_patient_id` VARCHAR(50), IN `in_created_at` DATETIME, IN `in_created_by` VARCHAR(50), IN `query_type` VARCHAR(30))   BEGIN
IF query_type='insert' THEN
INSERT INTO nursing_note (report,patient_id,created_at,created_by) VALUES(in_report,in_patient_id,in_created_at,in_created_by);
ELSEIF query_type='select' THEN
SELECT * FROM nursing_note WHERE patient_id=in_patient_id;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `patient_history` (IN `in_patient_id` VARCHAR(50), IN `in_req_id` VARCHAR(50), IN `in_history` VARCHAR(1000), IN `in_file` VARCHAR(200), IN `in_query_type` VARCHAR(50), IN `in_facId` VARCHAR(50))  NO SQL IF in_query_type='insert' THEN
        INSERT INTO patient_history (patient_id,request_id,history,file,facilityId) VALUES (in_patient_id,in_req_id,in_history,in_file,in_facId);
ELSEIF in_query_type = 'get_history' THEN
           SELECT 
      CONCAT(a.firstname, ' ', a.surname) AS name, 
      a.dob, 
      a.Gender AS gender, 
      a.Gender AS sex, 
      a.id,
      a.DOB AS dob, 
      IFNULL(a.phoneNo, '') AS phoneNo,
      b.test,
      b.created_by
    FROM patientrecords a
    JOIN lab_requisition b ON a.id = b.patient_id
    WHERE a.id = in_patient_id 
      AND b.request_id = in_req_id 
      AND a.facilityId = in_facId;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `patient_history2` (IN `in_patient_id` VARCHAR(50), IN `in_req_id` VARCHAR(50), IN `in_history` VARCHAR(1000), IN `in_file` VARCHAR(200), IN `in_query_type` VARCHAR(50), IN `in_facId` VARCHAR(50))  NO SQL IF in_query_type='insert' THEN
        INSERT INTO patient_history (patient_id,request_id,history,file,facilityId) VALUES (in_patient_id,in_req_id,in_history,in_file,in_facId);
ELSEIF in_query_type = 'get_history' THEN
    SELECT 
      CONCAT(a.firstname, ' ', a.surname) AS name, 
      a.dob, 
      a.Gender AS gender, 
      a.Gender AS sex, 
      a.id,
      a.DOB AS dob, 
      IFNULL(a.phoneNo, '') AS phoneNo,
      b.test,
      b.created_by
    FROM patientrecords a
    JOIN lab_requisition b ON a.id = b.patient_id
    WHERE a.id = in_patient_id 
      AND b.request_id = in_req_id 
      AND a.facilityId = in_facId;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `patient_nursing_notes` (IN `in_report` VARCHAR(200), IN `pat_id` VARCHAR(20), IN `create_at` DATETIME, IN `create_by` VARCHAR(50), IN `facId` VARCHAR(60), IN `query_type` VARCHAR(30))   BEGIN
IF query_type='insert' THEN
INSERT INTO `nursing_note`( `report`, `patient_id`, `created_at`, `created_by`,facilityId) 
VALUES (in_report,pat_id,create_at,create_by,facId);
ELSEIF query_type='select' THEN
SELECT * FROM nursing_note WHERE patient_id=pat_id AND facilityId=facId;

END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pending_prescription` (IN `query_type` VARCHAR(50), IN `in_status` VARCHAR(50), IN `facId` VARCHAR(50), IN `in_request_id` VARCHAR(50), IN `in_from` DATE, IN `in_to` DATE)  NO SQL BEGIN 
	IF query_type='patient-drugs' THEN 
    	SELECT drug,drug as drug_name, dosage, frequency, duration, additionalInfo, route, period, request_id FROM dispensary WHERE request_id=in_request_id AND status=in_status; 
	ELSEIF query_type='general-data' THEN 
    	SELECT a.request_id, a.patient_id, count(drug) as count, prescribed_by, concat(b.firstname, ' ', b.surname) as name FROM dispensary a JOIN patientrecords b ON (a.patient_id=b.id) WHERE a.status=in_status and a.facilityId=facId AND date(a.created_at) BETWEEN in_from AND in_to group by a.request_id, a.patient_id, prescribed_by,name LIMIT 50; 
    END IF; 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pending_txn` (IN `in_query_type` VARCHAR(50), IN `in_facilityId` VARCHAR(50), IN `in_transaction_id` VARCHAR(50), IN `in_description` VARCHAR(200), IN `in_head` VARCHAR(10), IN `in_subhead` VARCHAR(10), IN `in_amount` INT, IN `in_service_type` VARCHAR(50), IN `in_created_at` DATETIME, IN `in_patient_name` VARCHAR(150), IN `in_patient_id` VARCHAR(50), IN `in_patient_type` VARCHAR(50), IN `in_total_amount` INT, IN `in_tx_status` VARCHAR(45), IN `in_date_from` DATE, IN `in_date_to` DATE, IN `in_client_acc` VARCHAR(50), IN `in_item_code` VARCHAR(100), IN `in_expiry_date` DATE, IN `in_branch_location` VARCHAR(100), IN `in_qty_out` INT, IN `in_selling_price` VARCHAR(50), IN `in_request_id` VARCHAR(50), IN `in_mode_of_payment` VARCHAR(50), IN `in_consultation_number` VARCHAR(50))   BEGIN
    IF in_query_type = 'save' THEN
        INSERT INTO pending_txn (
            facilityId, transaction_id, description, head, subhead, amount, service_type, 
            created_at, patient_name, patient_id, patient_type, total_amount, 
            tx_status, client_acc, qty_out, selling_price, request_id, mode_of_payment, consultation_number
        ) 
        VALUES (
            in_facilityId, in_transaction_id, in_description, in_head, in_subhead, in_amount, in_service_type, 
            in_created_at, in_patient_name, in_patient_id, in_patient_type, 
            in_total_amount, in_tx_status, in_client_acc, in_qty_out, in_selling_price, in_request_id, in_mode_of_payment, in_consultation_number
        );
    
    ELSEIF in_query_type = 'get_by_status' THEN
        SELECT * FROM pending_txn 
        WHERE tx_status = in_tx_status 
        AND DATE(created_at) BETWEEN in_date_from AND in_date_to;
    
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_add_new_drug_purchase` (IN `in_receive_date` DATE, IN `in_item_name` VARCHAR(50), IN `in_po_no` VARCHAR(20), IN `in_qty_in` INT(11), IN `in_qty_out` INT(11), IN `in_store_type` VARCHAR(20), IN `in_grm_no` INT(11), IN `query_type` VARCHAR(20), IN `in_expiry_date` DATE, IN `in_unit_price` FLOAT(11), IN `in_mark_up` FLOAT(11), IN `in_selling_price` FLOAT(11), IN `in_transfer_from` VARCHAR(50), IN `in_status` VARCHAR(20), IN `in_transfer_to` VARCHAR(50), IN `in_branch_name` VARCHAR(30), IN `in_facilityId` VARCHAR(50), IN `in_trn_no` VARCHAR(50), IN `in_uniqueId` VARCHAR(50), IN `in_item_category` VARCHAR(100), IN `in_item_code` VARCHAR(70), IN `in_version_id` VARCHAR(50), IN `in_req_no` VARCHAR(50), IN `in_truck_no` VARCHAR(50), IN `in_waybill_no` VARCHAR(50), IN `in_other_info` VARCHAR(100), IN `in_cost_price` FLOAT, IN `in_supplier_code` VARCHAR(100), IN `in_supplier_name` VARCHAR(100), IN `in_reorder_level` INT, IN `in_receipt_no` VARCHAR(50), IN `in_user_id` VARCHAR(50), IN `in_generic_name` VARCHAR(100), IN `in_uom` VARCHAR(100), IN `in_barcode` VARCHAR(100))  NO SQL BEGIN

declare supplier_balance,new_supplier_balance float;
declare drug_code_data,drug_name_data,balance_data,store_data, facilityId_data varchar(50);
DECLARE supplier_name_data varchar(100);
DECLARE selling_price_data,price_data float;
declare expiry_date_data date;
declare new_drug_balance int;
declare var_amount float;
set var_amount=in_qty_in*in_cost_price ;
if query_type= "received" then

select balance  into supplier_balance from suppliersinfo where supplier_code=in_supplier_code;

set new_supplier_balance=supplier_balance-var_amount;
-- update the supplier info balance
update suppliersinfo set balance=new_supplier_balance where supplier_code=in_supplier_code;

-- insert into account entries
INSERT INTO supplier_entries (supplier_id,dr,cr,reference_no,facilityId,created_at,truckNo,waybillNo,description,version_id,cost_price,quantity)
VALUES (in_supplier_code,var_amount,0,'',in_facilityId,now(),in_truck_No,in_waybill_no,in_item_name,in_version_id,in_cost_price ,in_qty_in);


-- insert into store

INSERT INTO pharm_store_entries (receive_date, drug_name, po_no, qty_in,qty_out,store_type,grn_no, expiry_date,unit_price,mark_up,selling_price,transfer_from,transfer_to, branch_name,facilityId,uniqueId,drug_category,item_code,version_id, truckNo, waybillNo, otherInfo, cost_price, supplier_code, supplier_name, reorder_level, inserted_by,inserted_time,sales_type,barcode) 
VALUES(in_receive_date,in_item_name,in_po_no,in_qty_in, in_qty_out, in_store_type,in_grm_no,in_expiry_date, in_cost_price ,in_mark_up, in_selling_price,in_transfer_from,in_transfer_to, in_branch_name, in_facilityId,in_uniqueId, in_item_category,in_item_code,in_version_id, in_truck_no,in_waybill_no,in_other_info, in_cost_price, in_supplier_code, in_supplier_name,in_reorder_level,in_user_id,now(),"Purchase Order",in_barcode);

SELECT item_code,drug_name,price,balance, facilityId, expiry_date,selling_price,store, supplier_name into 
drug_code_data,drug_name_data,price_data,balance_data, facilityId_data,expiry_date_data ,selling_price_data,store_data, supplier_name_data
FROM `pharm_store` where drug_name=in_item_name and store=in_branch_name and expiry_date=in_expiry_date and barcode=in_barcode and
supplier_name= in_supplier_name and price = in_cost_price ; 

update pharm_store set selling_price=in_selling_price WHERE barcode=in_barcode and drug_name=in_item_name  and facilityId= in_facilityId  and store=in_branch_name;

if  drug_name_data=in_item_name and price_data=in_cost_price and store_data=in_branch_name and facilityId_data= in_facilityId and expiry_date_data=in_expiry_date and supplier_name_data=in_supplier_name THEN

set new_drug_balance=ifnull(balance_data,0)+in_qty_in;


update pharm_store set balance=new_drug_balance WHERE drug_name=in_item_name and selling_price=in_selling_price 
and  facilityId= in_facilityId and expiry_date=in_expiry_date and store=in_branch_name and supplier_name= in_supplier_name and price = in_cost_price;

ELSE

insert into pharm_store(item_code,drug_name,price,balance, facilityId, expiry_date,supplier_name,supplier_code,selling_price,store,generic_name,insert_date,reoder_level,uom,drug_category, barcode, grn_no)
values (in_item_code,in_item_name,in_cost_price,in_qty_in, in_facilityId,in_expiry_date,in_supplier_name,in_supplier_code,in_selling_price,in_branch_name,in_generic_name,now(),
        in_reorder_level,in_uom,in_item_category,in_barcode, in_grm_no);

end if;


-- call update_number_generator("grn",in_grm_no);

ELSEIF query_type="transfer" then
INSERT INTO pharm_store_entries (receive_date, item_name, po_no, qty_in,qty_out,store_type,grm_no,
        expiring_date,unit_price,mark_up,selling_price,transfer_from,transfer_to, 
        branch_name,facilityId,trn_number,uniqueId,item_category,item_code,version_id,
        truckNo, waybillNo, otherInfo, supplier_code, supplier_name,reorder_level,inserted_by,sales_type,barcode) 
VALUES(in_receive_date,in_item_name,in_po_no,in_qty_in, in_qty_out,
        in_store_type,in_grm_no, in_expiry_date,in_cost_price,
        in_mark_up,in_selling_price,in_transfer_from,in_transfer_to,
        in_branch_name,in_facilityId,in_trn_no,uniqueId,in_item_category,
        in_item_code,in_version_id,in_truck_no,in_waybill_no,in_other_info, 
        in_supplier_code, in_supplier_name,in_reorder_level,in_user_id,'Purchase Order',in_barcode);

call pharm_add_sale_department(in_trn_no, in_item_name, in_qty_in,in_expiry_date, in_selling_price,in_transfer_from, in_receive_date,in_item_category, in_item_code,in_transfer_to, in_version_id,in_facilityId, 0,in_status,in_req_no,
in_truck_no,in_waybill_no, in_other_info,in_supplier_code, in_supplier_name, in_receipt_no, in_user_id, in_barcode);
end if;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_add_new_pharm_store` (IN `in_store_name` VARCHAR(100), IN `in_store_location` VARCHAR(100), IN `in_phone_number` VARCHAR(100), IN `in_store_type` VARCHAR(100), IN `in_address` VARCHAR(100), IN `in_manage_by` VARCHAR(100), IN `in_facilityId` VARCHAR(100), IN `in_created_by` VARCHAR(100), IN `in_pharm_name` VARCHAR(100), IN `in_store_code` VARCHAR(100), IN `status` VARCHAR(50))  NO SQL BEGIN
if status='insert' THEN

INSERT INTO `pharm_branches`( `branch_name`, `location`, `address`, `phone`, `store_type`, `created_time`, `facilityId`, `admin_name`, `created_by`,store_code,manage_by) VALUES (in_store_name,in_store_location,in_address,in_phone_number,in_store_type,now(),in_facilityId,in_created_by,in_manage_by,in_store_code,in_manage_by);
ELSE
UPDATE `pharm_branches` SET `location`=in_store_location,`phone`=in_phone_number,`store_type`=in_store_type,`address`=in_address,`manage_by`=in_manage_by WHERE store_code=in_store_code and facilityId=in_facilityId;
end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_add_new_supplier` (IN `in_facilityId` VARCHAR(50), IN `in_supplier_name` VARCHAR(100), IN `in_address` VARCHAR(100), IN `in_phone` VARCHAR(20), IN `in_supplier_code` VARCHAR(50), IN `in_tinnumber` INT, IN `in_supplier_type` VARCHAR(50), IN `in_website` VARCHAR(40), IN `in_vat` INT, IN `in_email` VARCHAR(50), IN `in_other_info` VARCHAR(50), IN `in_version_id` VARCHAR(50), IN `in_balance` INT)   begin
declare supplier_balance,new_supplier_balance float;

SELECT balance into supplier_balance from suppliersinfo WHERE supplier_code=in_supplier_code ;

if supplier_balance is null  THEN
INSERT INTO suppliersinfo(facilityId,supplier_name,address,phone,supplier_code,tinnumber,supplier_type,website,vat, email,other_info,version_id, balance)
  VALUES (in_facilityId,in_supplier_name,in_address,in_phone,in_supplier_code,in_tinnumber,in_supplier_type,in_website,in_vat, in_email,in_other_info,in_version_id, in_balance);
 	IF in_balance != 0 THEN
	INSERT INTO `supplier_entries`(`supplier_id`, `dr`, `cr`, `reference_no`, `facilityId`, `created_at`, `description`, `truckNo`, `waybillNo`, `version_id`, `cost_price`, `quantity`) 
    VALUES (in_supplier_code, 0,in_balance, '', in_facilityId, now(), 'Opening Balance', 
           '', '', in_version_id, 0, 0);
           end if;
	ELSEIF in_balance = 0 THEN 
    INSERT INTO suppliersinfo(facilityId,supplier_name,address,phone,supplier_code,tinnumber,supplier_type,website,vat, email,other_info,version_id, balance)
  VALUES (in_facilityId,in_supplier_name,in_address,in_phone,in_supplier_code,in_tinnumber,in_supplier_type,in_website,in_vat, in_email,in_other_info,in_version_id, in_balance);
  ELSEIF in_balance>0 THEN
    SET new_supplier_balance=supplier_balance+ in_balance;
    
    update suppliersinfo set balance=new_supplier_balance WHERE supplier_code=in_supplier_code;
    
	INSERT INTO `supplier_entries`(`supplier_id`, `dr`, `cr`, `reference_no`, `facilityId`, `created_at`, `description`, `truckNo`, `waybillNo`, `version_id`, `cost_price`, `quantity`) 
    VALUES (in_supplier_code, 0,abs(in_balance), '', in_facilityId, now(), 'Opening Balance', 
           '', '', in_version_id, 0, 0);
           ELSEIF in_balance < 0 THEN
    SET new_supplier_balance=supplier_balance+ in_balance;
    
    update suppliersinfo set balance=new_supplier_balance WHERE supplier_code=in_supplier_code;
    
	INSERT INTO `supplier_entries`(`supplier_id`, `dr`, `cr`, `reference_no`, `facilityId`, `created_at`, `description`, `truckNo`, `waybillNo`, `version_id`, `cost_price`, `quantity`) 
    VALUES (in_supplier_code, 0,in_balance, '', in_facilityId, now(), 'Opening Balance', 
           '', '', in_version_id, 0, 0);
end if;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_add_sale_department` (IN `in_trn_number` VARCHAR(50), IN `in_item_name` VARCHAR(100), IN `in_qty_in` INT(100), IN `in_expiry_date` DATE, IN `in_selling_price` FLOAT(10), IN `in_branch_location` VARCHAR(100), IN `in_transaction_date` VARCHAR(20), IN `in_item_category` VARCHAR(50), IN `in_item_code` VARCHAR(90), IN `in_movement_source` VARCHAR(50), IN `in_version_id` VARCHAR(50), IN `in_facilityId` VARCHAR(50), IN `in_qty_out` INT(11), IN `in_status` VARCHAR(50), IN `in_req_no` VARCHAR(50), IN `in_truck_no` VARCHAR(50), IN `in_waybill_no` VARCHAR(50), IN `in_other_info` VARCHAR(100), IN `in_supplier_code` VARCHAR(50), IN `in_supplier_name` VARCHAR(200), IN `in_receipt_no` VARCHAR(50), IN `in_user_id` VARCHAR(50), IN `in_userName` VARCHAR(50), IN `_branch` VARCHAR(50), IN `in_barcode` VARCHAR(100), IN `in_patient_id` VARCHAR(100), IN `in_receiptSN` VARCHAR(100))  NO SQL BEGIN

declare quantity int;
declare quantity_approved int;
declare requisition_number int;
DECLARE items varchar(50);
DECLARE balance_quantity int;
DECLARE new_status varchar(50);
DECLARE approved_balance,new_item_balance1,balance_data1 int;

   
SELECT ifnull(balance,0) into balance_data1
FROM pharm_store where drug_name=in_item_name and selling_price=in_selling_price and expiry_date=in_expiry_date and store=in_branch_location AND item_code=in_item_code; 

set new_item_balance1=balance_data1-ifnull(in_qty_out,0);

 update pharm_store set balance=new_item_balance1  where drug_name=in_item_name and selling_price=in_selling_price and expiry_date=in_expiry_date and store=in_branch_location and item_code=in_item_code; 

INSERT INTO pharm_store_entries(item_status,version_id, trn_number,drug_name,qty_in,expiry_date,selling_price,transfer_from,
transfer_to,receive_date,qty_out,drug_category,item_code,facilityId,branch_name, grn_no, truckNo,waybillNo,otherInfo,supplier_code,supplier_name,uniqueId,inserted_time,inserted_by,userName,sales_type, barcode, patient_id)
 VALUES("pending",in_version_id,in_trn_number,in_item_name,in_qty_in,in_expiry_date,in_selling_price,in_branch_location,in_movement_source,now(),in_qty_out,
in_item_category,in_item_code,in_facilityId,in_branch_location,in_req_no,in_truck_no,in_waybill_no,in_other_info,in_supplier_code,in_supplier_name,in_receipt_no,now(),in_user_id,in_userName,"sales", in_barcode, in_patient_id);


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_drug_transfer` (IN `in_version_id` VARCHAR(100), IN `in_qty_in` INT(6), IN `in_expiry_date` DATE, IN `in_selling_price` FLOAT(10), IN `in_location_from` VARCHAR(100), IN `in_location_to` VARCHAR(100), IN `in_facilityId` VARCHAR(100), IN `in_item_name` VARCHAR(100), IN `in_receive_date` DATE, IN `in_unit_price` FLOAT(10), IN `in_mark_up` FLOAT(10), IN `supplier_name` VARCHAR(50), IN `supplier_code` VARCHAR(50))   BEGIN
DECLARE trn int;
declare item_code_data,description_data,price_data,balance_data, facilityId_data varchar(50);
declare expiry_date_data date;
declare new_item_balance,transfers_balance,new_transfers_balance int;

declare item_code_data1,description_data1,price_data1,balance_data1 varchar(50);
declare expiry_date_data1 date;
declare new_item_balance1 int;

-- SELECT max(ifNull(code_no,0)+1)  INTO trn from number_generator WHERE prefix='trn';

SELECT item_code,drug_name,price,balance, expiry_date
into item_code_data1,description_data1,price_data1,balance_data1,expiry_date_data1 
FROM `pharm_store` where drug_name=in_item_name and price=in_unit_price and expiry_date=in_expiry_date and store=in_location_from AND facilityId=in_facilityId; 

set new_item_balance1=balance_data1-in_qty_in;

update `pharm_store`set balance=new_item_balance1  where drug_name=description_data1 and price=price_data1 and expiry_date=expiry_date_data1  and store=in_location_from; 

SELECT balance INTO transfers_balance from pharm_store where drug_name=description_data1 and price=price_data1 and expiry_date=expiry_date_data1  and store = in_location_to;

IF transfers_balance is null then 
INSERT INTO `pharm_store`(`balance`, `drug_name`,`item_code`, `price`, `facilityId`, `expiry_date`, `store`, `selling_price`, `supplier_name`, `supplier_code`, `insert_date`) 
VALUES (in_qty_in,in_item_name,item_code_data1,in_unit_price,in_facilityId,in_expiry_date,in_location_to,in_selling_price,supplier_name,supplier_code,now());

INSERT INTO pharm_store_entries(receive_date,drug_name,item_code,`expiry_date`,qty_out,qty_in,transfer_from,`transfer_to`,unit_price,selling_price,mark_up,branch_name,facilityId,version_id,supplier_code,supplier_name,sales_type)
VALUES(now(),in_item_name,item_code_data1,in_expiry_date,in_qty_in, 0,in_location_from,in_location_to,in_unit_price,in_selling_price,in_mark_up, in_location_to ,in_facilityId,in_version_id,supplier_code,supplier_name,concat("Transfer to ", in_location_to));

INSERT INTO pharm_store_entries(receive_date,drug_name,item_code,expiry_date,qty_out,qty_in,transfer_from,`transfer_to`,unit_price,selling_price,mark_up,branch_name,facilityId,version_id,supplier_code,supplier_name,sales_type)
VALUES(now(),in_item_name,item_code_data1,in_expiry_date,0 ,in_qty_in,in_location_from,in_location_to,in_unit_price,in_selling_price,in_mark_up,in_location_to,in_facilityId, in_version_id,supplier_code,supplier_name,concat("Transfer to ", in_location_to));


ELSE
SET new_transfers_balance = transfers_balance + in_qty_in;
UPDATE pharm_store SET balance = new_transfers_balance  where drug_name=description_data1 and price=price_data1 and expiry_date=expiry_date_data1  and store = in_location_to;


INSERT INTO pharm_store_entries(receive_date,drug_name,`item_code`,expiry_date,qty_out,qty_in,transfer_from,`transfer_to`,unit_price,selling_price,mark_up,facilityId,supplier_code,supplier_name,version_id,sales_type,branch_name)
VALUES(now(),in_item_name,item_code_data1,in_expiry_date,in_qty_in, 0,in_location_from,in_location_to,in_unit_price,in_selling_price,in_mark_up,in_facilityId,supplier_code,supplier_name,in_version_id ,concat("Transfer to ", in_location_to), in_location_to);

INSERT INTO pharm_store_entries(receive_date,drug_name,`item_code`,expiry_date,qty_out,qty_in,transfer_from,`transfer_to`,unit_price,selling_price,mark_up,branch_name,facilityId,version_id,supplier_code,supplier_name,sales_type)
VALUES(now(),in_item_name,item_code_data1,in_expiry_date,0 ,in_qty_in,in_location_from,in_location_to,in_unit_price,in_selling_price,in_mark_up,in_location_to,in_facilityId,in_location_to,supplier_code,supplier_name,concat("Transfer to ", in_location_to));
	
end IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_getReceiptData` (IN `in_receipt_no` VARCHAR(100), IN `in_facilityId` VARCHAR(100))  NO SQL BEGIN
    SELECT 
        description, 
        description AS item_name, 
        amount AS amount, 
        (amount) AS price, 
        amount AS debit, 
        qty_out AS qty,  -- Assuming each transaction represents a single quantity
        client_acc AS acct, 
        (amount) AS unit_price,
        consultation_number AS consultation_number
    FROM pending_txn 
    WHERE transaction_id = in_receipt_no 
        AND facilityId = in_facilityId
        AND tx_status = 'paid';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_getReceiptDatab4` (IN `in_receipt_no` VARCHAR(100), IN `in_facilityId` VARCHAR(100))  NO SQL SELECT description, description as item_name, dr as amount, (dr/quantity) as price , dr as debit, quantity as qty,acct, (dr/quantity) as unit_price  from account_entries where reference_no=in_receipt_no and facilityId=in_facilityId AND dr > 0$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_client` (IN `in_facilityId` VARCHAR(50))  NO SQL SELECT accountNo,accName,balance,contactEmail,contactAddress,contactPhone FROM patientfileno WHERE facilityId=in_facilityId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_druglist` (IN `facId` VARCHAR(70), IN `query_type` VARCHAR(20))  NO SQL BEGIN
IF query_type = 'stock' THEN
SELECT balance,item_code, price,drug_name,expiry_date,selling_price,supplier_name,insert_date,barcode,grn_no from pharm_store WHERE balance>0 AND facilityId = facId and (date(expiry_date)>now() OR expiry_date='1111-11-11' OR expiry_date='')   ORDER BY `drug_name` ASC;
ELSEIF query_type = 'out_of_stock' THEN 
SELECT balance, price,drug_name,expiry_date,selling_price,supplier_name,insert_date,barcode,grn_no from pharm_store WHERE balance <= 0 AND facilityId = facId ORDER BY `grn_no` DESC;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_drug_sale_search` (IN `in_drug_name` VARCHAR(50), IN `in_facilityId` VARCHAR(100), IN `in_from` INT, IN `in_to` INT, IN `in_store` VARCHAR(100))   SELECT * FROM `pharm_store` WHERE  balance>0 and (drug_name like in_drug_name or drug_category LIKE  in_drug_name or uom LIKE in_drug_name or generic_name LIKE in_drug_name or barcode LIKE in_drug_name) and (date(expiry_date)>now() OR expiry_date='1111-11-11' OR expiry_date='') and facilityId =in_facilityId and store=in_store LIMIT in_from,in_to$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_drug_search` (IN `query_type` VARCHAR(100), IN `facId` VARCHAR(50), IN `in_from` INT, IN `in_to` INT, IN `in_store_type` VARCHAR(50))   SELECT * FROM `pharm_store` WHERE drug_name like query_type AND facilityId = facId AND (date(expiry_date)>now() OR expiry_date='1111-11-11' OR expiry_date='') AND store=in_store_type AND balance>0 ORDER BY drug_name ASC LIMIT in_from, in_to$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_drug_view` (IN `in_branch_name` VARCHAR(100), IN `in_item_code` VARCHAR(100), IN `in_facilityId` VARCHAR(50), IN `in_date_from` DATE, IN `in_date_to` DATE, IN `in_drug_name` VARCHAR(100), IN `in_expiry_date` DATE)  NO SQL SELECT expiry_date,receive_date,drug_name,branch_name as store,qty_in,qty_out,selling_price FROM `pharm_store_entries` WHERE expiry_date=in_expiry_date and item_code=in_item_code and facilityId=in_facilityId and date(inserted_time) between in_date_from and in_date_to$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_expiry_alert` (IN `facId` VARCHAR(50))  NO SQL SELECT * FROM pharm_store WHERE DATE_FORMAT(expiry_date, '%Y-%m-%d') BETWEEN DATE_FORMAT(NOW(), '%Y-%m-%d') AND DATE_FORMAT(DATE_ADD(NOW(),INTERVAL 6 MONTH), '%Y-%m-%d')  AND (facilityId=facId) ORDER by expiry_date ASC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_pharm_store` (IN `in_facilityId` VARCHAR(50))  NO SQL SELECT branch_name as store_name,store_code,location as location,phone as phone,store_type as storeType,address,manage_by as manage_by FROM `pharm_branches` WHERE facilityId=in_facilityId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_pharm_users` (IN `in_facilityId` VARCHAR(50))  NO SQL SELECT * FROM users where facilityId=in_facilityId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_purchase_drugs` (IN `in_facilityId` VARCHAR(50), IN `in_from` INT(15), IN `in_to` INT(15), IN `query_type` VARCHAR(60), IN `in_store` VARCHAR(100))  NO SQL begin
if query_type="by_store" THEN
SELECT * FROM `pharm_store` WHERE (date(expiry_date)>now() OR expiry_date='1111-11-11' OR expiry_date='') AND store = in_store AND facilityId=in_facilityId and balance>0 LIMIT in_from,in_to;
ELSE 
SELECT * FROM `pharm_store` WHERE (date(expiry_date)>now() OR expiry_date='1111-11-11' OR expiry_date='') and facilityId=in_facilityId AND balance > 0;
end if;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_reorder_level` (IN `facId` VARCHAR(50))  NO SQL SELECT * FROM pharm_store WHERE balance < reoder_level AND facilityId=facId and balance>0$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_sales_drugs` (IN `in_facilityId` VARCHAR(50), IN `query_type` VARCHAR(50), IN `in_from` INT, IN `in_to` INT)  NO SQL BEGIN
if query_type='Show All' THEN 
SELECT item_code,ifnull(drug_category ,"") as drug_category,ifnull(generic_name ,"") as generic_name,ifnull(uom ,"") as uom,balance,drug_name,item_code,facilityId,expiry_date,store,selling_price FROM `pharm_store` WHERE facilityId=in_facilityId and (date(expiry_date)>now() OR expiry_date='1111-11-11' OR expiry_date='') and balance>0 ORDER BY `drug_name` ASC;
 ELSE 
SELECT item_code,ifnull(drug_category ,"") as drug_category,ifnull(generic_name ,"") as generic_name,ifnull(uom ,"") as uom,balance,drug_name,item_code,facilityId,expiry_date,store,selling_price FROM `pharm_store` WHERE facilityId=in_facilityId and (date(expiry_date)>now() OR expiry_date='1111-11-11' OR expiry_date='') and store=query_type and balance>0 ORDER BY `drug_name` ASC LIMIT in_from,in_to;
 end if;
 end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_supplier` (IN `_supplier_code` VARCHAR(50))  NO SQL SELECT `facilityId`, `supplier_name`, `date`, `address`, `phone`, `supplier_code`, `balance`, `tinnumber` `email` FROM `suppliersinfo` WHERE supplier_code=_supplier_code$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_supplierr_statement` (IN `in_supplier_code` VARCHAR(50), IN `in_date_from` DATE, IN `in_date_to` DATE, IN `in_facilityId` VARCHAR(60))   SELECT  0 AS `total`,`entry_id`, `supplier_id`, `dr`, `cr`, `reference_no`, `facilityId`, `created_at`, `description`, `truckNo`, `waybillNo`, `version_id`, `cost_price`, `quantity` FROM supplier_entries where supplier_id=in_supplier_code and date(created_at) between in_date_from and in_date_to AND  facilityId=in_facilityId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_supplier_count` (IN `in_facilityId` VARCHAR(50))  NO SQL SELECT COUNT(*) as num FROM `suppliersinfo` WHERE facilityId=in_facilityId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_get_supplier_info` (IN `in_facilityId` VARCHAR(50))  NO SQL SELECT `facilityId`, `supplier_name`, `date`, `address`, `phone`, `supplier_code`, `balance`, `tinnumber` `email` FROM `suppliersinfo` WHERE facilityId=in_facilityId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_reports_dashboard` (IN `in_date_from` DATE, IN `in_date_to` DATE, IN `in_facilityid` VARCHAR(100), IN `query_type` VARCHAR(50))  NO SQL begin

if query_type ='Purchase summary' then

SELECT sum(qty_in*unit_price) as total FROM `pharm_store_entries` where sales_type ='Purchase Order' AND date(receive_date) BETWEEN in_date_from and in_date_to and facilityId=in_facilityid;

elseif query_type ='Purchase category summary' then

SELECT receive_date,drug_name as description,qty_in as qty,selling_price, unit_price,unit_price*qty_in as amount,inserted_by, branch_name,supplier_name FROM `pharm_store_entries` where sales_type ='Purchase Order' AND date(receive_date) BETWEEN in_date_from and in_date_to and facilityId=in_facilityid;

elseif query_type = 'Sales summary' then
  SELECT 
    SUM(qty_out * selling_price) AS total 
  FROM pharm_store_entries 
  WHERE 
    DATE(receive_date) BETWEEN in_date_from AND LEAST(in_date_to, '2025-05-05') 
    AND facilityId = in_facilityid 
    AND qty_out > 0 
    AND sales_type = 'sales';


elseif query_type = 'Sales category summary' then
  SELECT  
    receive_date,
    drug_name AS description,
    qty_out AS qty,
    selling_price, 
    selling_price * qty_out AS amount,
    inserted_by,
    sales_type, 
    branch_name,
    otherInfo, 
    grn_no AS mop 
  FROM pharm_store_entries 
  WHERE 
    DATE(receive_date) BETWEEN in_date_from AND LEAST(in_date_to, '2025-05-05') 
    AND facilityId = in_facilityid 
    AND qty_out > 0 
    AND sales_type = 'sales';

elseif query_type ='Sale summary' then
SELECT 
            SUM(amount) as total 
        FROM 
            `pending_txn` 
        WHERE 
            date(transaction_date) BETWEEN in_date_from AND in_date_to 
            AND facilityId = in_facilityid 
            AND qty_out > 0 
            AND service_type = 'PHARMACY'
            AND tx_status != 'pending';

-- SELECT sum(qty_out*selling_price) as total FROM `pharm_store_entries` where date(receive_date) BETWEEN in_date_from and in_date_to and facilityId=in_facilityid AND qty_out > 0 AND sales_type="sales" ;


elseif query_type ='Sale category summary' then
SELECT 
            transaction_date as receive_date,
            description,
            qty_out as qty,
            amount as amount,
            selling_price as selling_price,
            total_amount as amounts,
            cashier_id as inserted_by,
            'sales' as sales_type,
            facilityId as branch_name,
            patient_name as otherInfo,
            mode_of_payment as mop
        FROM 
            `pending_txn` 
        WHERE 
            date(transaction_date) BETWEEN in_date_from AND in_date_to 
            AND facilityId = in_facilityid 
            AND qty_out > 0 
            AND service_type = 'PHARMACY'
            AND tx_status = 'paid';

-- SELECT  receive_date,drug_name as description,qty_out as qty,selling_price, selling_price*qty_out as amount,inserted_by,sales_type, branch_name,otherInfo, grn_no as mop FROM `pharm_store_entries` where date(receive_date) BETWEEN in_date_from and in_date_to and facilityid=in_facilityid AND qty_out > 0 AND sales_type="sales";


elseif query_type ='Expenses summary' then

SELECT sum(credit) as total FROM `transactions` where acct ='EXPENSES' and facilityId=in_facilityid and date(createdAt) between in_date_from and in_date_to;
elseif query_type ='Expenses summary' then

SELECT sum(credit) as total FROM `transactions` where acct ='EXPENSES' and facilityId=in_facilityid and date(createdAt) between in_date_from and in_date_to;


elseif query_type ='Discount summary' then
SELECT sum(credit) as total FROM `transactions` where acct ='60000' and facilityId=in_facilityid and date(createdAt) between in_date_from and in_date_to;

elseif query_type ='Discount category summary' then
SELECT description,credit,enteredBy,createdAt,customer_name, branch_name FROM `transactions` where acct ='60000' and facilityId=in_facilityid and date(createdAt) between in_date_from and in_date_to;

elseif query_type ='Debt summary' then

SELECT sum(balance) as total FROM patientfileno where facilityId=in_facilityid AND balance < 0  AND accountNo != in_facilityid;
elseif query_type ='Debt summary' then


select date(createdAt) as receive_date, accname as description,contactPhone,balance as amount from patientfileno where facilityId=in_facilityid AND balance < 0 AND accountNo != '';

elseif query_type ='Debt category summary' then

select date(createdAt) as receive_date, accname as description,contactPhone,balance as amount from patientfileno where facilityId=in_facilityid AND balance < 0 AND accountNo != '';

elseif query_type ='reprint' then
  select *, SUM(amount) 
  FROM pending_txn 
  WHERE 
    facilityId = in_facilityid 
    AND DATE(created_at) BETWEEN in_date_from AND in_date_to
    AND tx_status = 'paid'
  GROUP BY transaction_id;
  
  elseif query_type = 'pending' then
  SELECT *
  FROM pending_txn
  WHERE 
    tx_status != 'pending'
    AND mode_of_payment = 'BILL'
    AND facilityId = in_facilityid
    AND DATE(created_at) BETWEEN in_date_from AND in_date_to;
--  GROUP BY transaction_id;


end if;

end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_reports_dashboards` (IN `in_date_from` DATE, IN `in_date_to` DATE, IN `in_facilityid` VARCHAR(100), IN `query_type` VARCHAR(50))   begin

if query_type ='Purchase summary' then

SELECT sum(qty_in*unit_price) as total FROM `pharm_store_entries` where sales_type ='Purchase Order' AND date(receive_date) BETWEEN in_date_from and in_date_to and facilityId=in_facilityid;

elseif query_type ='Purchase category summary' then

SELECT receive_date,drug_name as description,qty_in as qty,selling_price, unit_price,unit_price*qty_in as amount,inserted_by, branch_name,supplier_name FROM `pharm_store_entries` where sales_type ='Purchase Order' AND date(receive_date) BETWEEN in_date_from and in_date_to and facilityId=in_facilityid;

elseif query_type ='Sales summary' then
SELECT 
            SUM(amount) as total 
        FROM 
            `pending_txn` 
        WHERE 
            date(transaction_date) BETWEEN in_date_from AND in_date_to 
            AND facilityId = in_facilityid 
            AND qty_out > 0 
            AND service_type = 'PHARMACY'
            AND tx_status != 'pending';

-- SELECT sum(qty_out*selling_price) as total FROM `pharm_store_entries` where date(receive_date) BETWEEN in_date_from and in_date_to and facilityId=in_facilityid AND qty_out > 0 AND sales_type="sales" ;

elseif query_type ='Sales category summary' then
SELECT 
            transaction_date as receive_date,
            description,
            qty_out as qty,
            amount as selling_price,
            total_amount as amount,
            cashier_id as inserted_by,
            'sales' as sales_type,
            facilityId as branch_name,
            patient_name as otherInfo,
            mode_of_payment as mode_of_payment
        FROM 
            `pending_txn` 
        WHERE 
            date(transaction_date) BETWEEN in_date_from AND in_date_to 
            AND facilityId = in_facilityid 
            AND qty_out > 0 
            AND service_type = 'PHARMACY'
            AND tx_status != 'pending';

-- SELECT  receive_date,drug_name as description,qty_out as qty,selling_price, selling_price*qty_out as amount,inserted_by,sales_type, branch_name,otherInfo, grn_no as mop FROM `pharm_store_entries` where date(receive_date) BETWEEN in_date_from and in_date_to and facilityid=in_facilityid AND qty_out > 0 AND sales_type="sales";


elseif query_type ='Expenses summary' then

SELECT sum(credit) as total FROM `transactions` where acct ='EXPENSES' and facilityId=in_facilityid and date(createdAt) between in_date_from and in_date_to;
elseif query_type ='Expenses summary' then

SELECT sum(credit) as total FROM `transactions` where acct ='EXPENSES' and facilityId=in_facilityid and date(createdAt) between in_date_from and in_date_to;


elseif query_type ='Discount summary' then
SELECT sum(credit) as total FROM `transactions` where acct ='60000' and facilityId=in_facilityid and date(createdAt) between in_date_from and in_date_to;

elseif query_type ='Discount category summary' then
SELECT description,credit,enteredBy,createdAt,customer_name, branch_name FROM `transactions` where acct ='60000' and facilityId=in_facilityid and date(createdAt) between in_date_from and in_date_to;

elseif query_type ='Debt summary' then

SELECT sum(balance) as total FROM patientfileno where facilityId=in_facilityid AND balance < 0  AND accountNo != in_facilityid;
elseif query_type ='Debt summary' then


select date(createdAt) as receive_date, accname as description,contactPhone,balance as amount from patientfileno where facilityId=in_facilityid AND balance < 0 AND accountNo != '';

elseif query_type ='Debt category summary' then

select date(createdAt) as receive_date, accname as description,contactPhone,balance as amount from patientfileno where facilityId=in_facilityid AND balance < 0 AND accountNo != '';

elseif query_type ='reprint' then
select *,SUM(dr) FROM account_entries where facilityId=in_facilityid AND date(createdAt) between in_date_from and in_date_to GROUP BY reference_no;


end if;

end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_service_transaction` (IN `in_description` VARCHAR(1000), IN `in_acct` VARCHAR(50), IN `service_amount` INT, IN `in_receiptDateSN` VARCHAR(70), IN `in_receiptSN` VARCHAR(50), IN `in_mode_of_payment` VARCHAR(20), IN `patientId` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `sourceAcct` VARCHAR(50), IN `userId` VARCHAR(50), IN `in_service_head` VARCHAR(50), IN `txnType` VARCHAR(10), IN `in_date` DATETIME, IN `in_payables_head` VARCHAR(50), IN `in_recievables_head` VARCHAR(50), IN `in_bank_name` VARCHAR(50), IN `in_txn_date` DATE, IN `in_discount` INT, IN `in_discount_head` VARCHAR(50), IN `in_customer_name` VARCHAR(50), IN `in_branch_name` VARCHAR(50), IN `qty` VARCHAR(50), IN `in_version_id` VARCHAR(50), IN `cus_phone` VARCHAR(20), IN `cus_bank` VARCHAR(30), IN `cus_acc_no` VARCHAR(20), IN `transaction_amount` VARCHAR(50), IN `bus_bank` VARCHAR(30), IN `bus_bank_acc_no` VARCHAR(100), IN `in_amount_paid` INT, IN `in_truck_no` VARCHAR(50), IN `in_waybill_no` VARCHAR(50), IN `in_item_list` VARCHAR(500), IN `in_payment_type` VARCHAR(100), IN `in_price` INT(11), IN `in_item_code` VARCHAR(100), IN `in_expiry_date` DATE, IN `in_salesFrom` VARCHAR(100), IN `in_userName` VARCHAR(100), IN `_branch` VARCHAR(100), IN `patientType` VARCHAR(50))   BEGIN
    declare client_balance int;
    declare main_balance int;
    declare receivable int;
    DECLARE instant_balance int;
    DECLARE cash_amount int;
    DECLARE new_bal int;

    select balance into client_balance  from `patientfileno` where accountNo=in_acct AND facilityId=in_facId;

    set cash_amount = service_amount - in_discount;
    set main_balance = client_balance-cash_amount;
    set receivable  = cash_amount-client_balance;
    set instant_balance = client_balance + cash_amount;
    set new_bal = client_balance - cash_amount;


    IF txnType = 'insta' THEN

        update  `patientfileno` set balance= new_bal where accountNo=in_acct AND facilityId=in_facId;

        -- insert into account_entries (version_id, acct,dr,cr,reference_no,description,facilityId,createdAt,truckNo,waybillNo,quantity)
         --   values (in_version_id, in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date,in_truck_no,in_waybill_no,qty);

        INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
        -- `client_entries`(`acct`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
        VALUES (in_acct,in_description,abs(service_amount),0,in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);
 
        insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
        -- transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date, customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
           -- values (in_version_id, in_description,in_service_head,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
        values (in_facId,in_txn_date, in_description,in_service_head,0,service_amount,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);


        IF in_discount > 0 THEN
            -- insert into account_entries (version_id, acct,dr,cr,reference_no,description,facilityId,createdAt,truckNo,waybillNo,quantity)
            -- values (concat(in_version_id, '-2'), in_acct,in_discount,0,in_receiptDateSN,concat('Discount on (', in_item_list,')'),in_facId,in_date,in_truck_no,in_waybill_no,qty);
            insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
      
            -- transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date, customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
            -- values (concat(in_version_id, '-2'), concat('Discount on (', in_item_list,')'),in_discount_head,0,in_discount ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,0,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
            values (in_facId,in_txn_date, concat('Discount on (', in_item_list,')'),in_discount_head,0,service_amount,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);

            -- INSERT INTO `client_entries`(`accountNo`, `version_id`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
            -- VALUES (in_acct,in_version_id,concat('Discount on (', in_item_list,')'),abs(in_discount),0,in_facId,in_mode_of_payment,in_receiptSN,0);
            INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
            VALUES (in_acct,concat('Discount on (', in_item_list,')'),0,abs(in_discount),in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);
 
            update `patientfileno`  set balance= new_bal+in_discount where accountNo=in_acct AND facilityId=in_facId;
        END IF;


    -- if the customer is registered
    ELSE

        -- if the customer has balance more than what is buying
        if main_balance  > 0  then
            -- INSERT INTO `client_entries`(`accountNo`, `version_id`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
            -- VALUES (in_acct,in_version_id,in_description,0,abs(service_amount),in_facId,in_mode_of_payment,in_receiptSN,qty);

            update `patientfileno`  set balance= new_bal where accountNo=in_acct AND facilityId=in_facId;

         INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
            VALUES (in_acct,in_description,abs(service_amount), 0,in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);
 
           insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
           values (in_facId,in_txn_date, in_description,in_service_head,0,service_amount,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);

            insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
            -- insert into transactions  (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date, customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
            values (in_facId,in_txn_date, in_description,in_payables_head,abs(cash_amount),0 ,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);


            -- if there is discount
            IF in_discount > 0 THEN
               -- insert into account_entries (version_id, acct,dr,cr,reference_no,description,facilityId,createdAt,truckNo,waybillNo,quantity)
                -- values (concat(in_version_id, '-6'), in_acct,in_discount,0,in_receiptDateSN,concat('Discount on (', in_item_list,')'),in_facId,in_date,in_truck_no,in_waybill_no,qty);
                insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
                -- values (concat(in_version_id, '-6'), concat('Discount on (', in_item_list,')'),in_discount_head,0,in_discount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
                values (in_facId,in_txn_date, concat('Discount on (', in_item_list,')'),in_discount_head,0,service_amount,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);
                
                INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
                -- VALUES (in_acct,in_version_id,concat('Discount on (', in_item_list,')'),abs(in_discount),0,in_facId,in_mode_of_payment,in_receiptSN,0);
                VALUES (in_acct,0,concat('Discount on (', in_item_list,')'),abs(in_discount),in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);
 
                update  `patientfileno` set balance= new_bal+in_discount where accountNo=in_acct AND facilityId=in_facId;
  
            END IF;

        -- if the customer has not enough balance
        elseif main_balance < 0 then
            update  `patientfileno` set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

            -- insert into account_entries (version_id, acct,dr,cr,reference_no,description,facilityId,createdAt,truckNo,waybillNo,quantity)
            -- values (concat(in_version_id, '-7'), in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date,in_truck_no,in_waybill_no,qty);
 
            -- INSERT INTO `client_entries`(`accountNo`, `version_id`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
            -- VALUES (in_acct,in_version_id,in_description,0,abs(service_amount),in_facId,in_mode_of_payment,in_receiptSN,qty);
            INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
            VALUES (in_acct,in_description,abs(service_amount),0, in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);
 
            update  `patientfileno` set balance= new_bal where accountNo=in_acct AND facilityId=in_facId;
            
            insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
            values (in_facId,in_txn_date, in_description,in_service_head,0,service_amount,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);

            -- insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date,     customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
            -- values (concat(in_version_id, '-8'), in_description,in_service_head,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);


            -- if the current balance is zero
            if client_balance = 0 then
               -- insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date,     customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
               -- values (concat(in_version_id, '-9'), in_description,in_recievables_head,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
                insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
                values (in_facId,in_txn_date, in_description,in_recievables_head,abs(cash_amount),0,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);


                IF in_discount > 0 THEN
                 --   insert into account_entries (version_id, acct,dr,cr,reference_no,description,facilityId,createdAt,truckNo,waybillNo,quantity)
                 --   values (concat(in_version_id, '-10'), in_acct,in_discount,0,in_receiptDateSN,concat('Discount on (', in_item_list,')'),in_facId,in_date,in_truck_no,in_waybill_no,qty);
                   -- insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date,     customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
                  --  values (concat(in_version_id, '-10'), concat('Discount on (', in_item_list,')'),in_discount_head,0,in_discount ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
                    insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
                    values (in_facId,in_txn_date, concat('Discount on (', in_item_list,')'),in_discount_head,0,service_amount,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);
            
                   --  INSERT INTO `client_entries`(`accountNo`, `version_id`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
                   --  VALUES (in_acct,in_version_id,concat('Discount',' for (', in_item_list, ')'),abs(in_discount),0,in_facId,in_mode_of_payment,in_receiptSN,0);
                    INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
              
                    VALUES (in_acct,concat('Discount on (', in_item_list,')'), 0, abs(in_discount),in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);
 
                    update  `patientfileno` set balance= new_bal+in_discount where accountNo=in_acct AND facilityId=in_facId;
  
                END IF;

            elseif client_balance > 0  then

                --  insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date, customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
               --  values (concat(in_version_id, '-11'), in_description,in_payables_head,abs(client_balance),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
                insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
                values (in_facId,in_txn_date, in_description,in_payables_head,abs(client_balance),0,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);

                -- insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date,     customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
                -- values (concat(in_version_id, '-12'), in_description,in_recievables_head,abs(receivable),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
               -- insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`)
               -- values (in_facId,in_txn_date, concat('Discount on (', in_item_list,')'),in_discount_head,0,service_amount,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId);
            
                insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
                values (in_facId,in_txn_date, in_description,in_recievables_head,abs(receivable),0,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);
        


                IF in_discount > 0 THEN
                -- insert into account_entries (version_id, acct,dr,cr,reference_no,description,facilityId,createdAt,truckNo,waybillNo,quantity)
                -- values (concat(in_version_id, '-13'), in_acct,in_discount,0,in_receiptDateSN,concat('Discount on (', in_item_list,')'),in_facId,in_date,in_truck_no,in_waybill_no,qty);
                -- insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date, customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
                
                -- values (concat(in_version_id, '-13'), concat('Discount on (', in_item_list,')'),in_discount_head,0 ,in_discount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
                 insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
                values (in_facId,in_txn_date, concat('Discount on (', in_item_list,')'),in_discount_head,0,abs(in_discount),userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);


              --  INSERT INTO `client_entries`(`accountNo`, `version_id`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
              --  VALUES (in_acct,in_version_id,concat('Discount on (', in_item_list,')'),abs(in_discount),0,in_facId,in_mode_of_payment,in_receiptSN,0);
                INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
              
                VALUES (in_acct,concat('Discount on (', in_item_list,')'),0, abs(in_discount), in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);
 
                update  `patientfileno` set balance= new_bal+in_discount where accountNo=in_acct AND facilityId=in_facId;
                END IF;

            elseif client_balance < 0  then

               -- insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date, customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
                -- values (concat(in_version_id, '-14'), in_description,in_recievables_head,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
                insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
                values (in_facId,in_txn_date, in_description,in_recievables_head,abs(receivable),0,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);
    
                -- INSERT INTO `client_entries`(`accountNo`, `version_id`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
                -- VALUES (in_acct,in_version_id,in_description,0,abs(service_amount),in_facId,in_mode_of_payment,in_receiptSN,qty);
                -- update  `patientfileno` set balance= new_bal where accountNo=in_acct AND facilityId=in_facId;

                IF in_discount > 0 THEN
                   -- insert into account_entries (version_id, acct,dr,cr,reference_no,description,facilityId,createdAt,truckNo,waybillNo,quantity)
           -- values (concat(in_version_id, '-15'), in_acct,in_discount,0,in_receiptDateSN,concat('Discount on (', in_item_list,')'),in_facId,in_date,in_truck_no,in_waybill_no,qty);
                -- insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date, customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
                -- values (concat(in_version_id, '-15'), concat('Discount on (', in_item_list,')'),in_discount_head,0 ,in_discount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
                insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
                values (in_facId,in_txn_date, concat('Discount on (', in_item_list,')'),in_discount_head,0,service_amount,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);
            
                -- INSERT INTO `client_entries`(`accountNo`, `version_id`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
                -- VALUES (in_acct,in_version_id,concat('Discount on (', in_item_list,')'),abs(in_discount),0,in_facId,in_mode_of_payment,in_receiptSN,0);
                INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
              
                VALUES (in_acct,concat('Discount on (', in_item_list,')'), 0,abs(in_discount), in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);
 
                update  `patientfileno` set balance= new_bal+in_discount where accountNo=in_acct AND facilityId=in_facId;
                
                END IF;

            end if;
        
        -- if the current balance is equal to what he has in the account
        elseif  main_balance = 0 then

            update  `patientfileno` set balance= main_balance  where accountNo=in_acct AND facilityId=in_facId;

            -- insert into account_entries (version_id, acct,dr,cr,reference_no,description,facilityId,createdAt,truckNo,waybillNo,quantity)
            -- values (concat(in_version_id, '-16'), in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date,in_truck_no,in_waybill_no,qty);
            
            -- INSERT INTO `client_entries`(`accountNo`, `version_id`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
            -- VALUES (in_acct,in_version_id,in_description,0,abs(service_amount),in_facId,in_mode_of_payment,in_receiptSN,qty);
             INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
            VALUES (in_acct,in_description,abs(service_amount),0, in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);
 
            update  `patientfileno` set balance= new_bal where accountNo=in_acct AND facilityId=in_facId;
  
            -- insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date, customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
            -- values (concat(in_version_id, '-17'), in_description,in_service_head,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
            insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
            values (in_facId,in_txn_date, in_description,in_service_head,0,service_amount,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);
    

            -- insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date, customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
            -- values (concat(in_version_id, '-18'), in_description,in_payables_head,abs(client_balance),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
            insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
            values (in_facId,in_txn_date, in_description,in_payables_head,abs(client_balance),0,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);


            IF in_discount > 0 THEN
               -- insert into account_entries (version_id, acct,dr,cr,reference_no,description,facilityId,createdAt,truckNo,waybillNo,quantity)
          --  values (concat(in_version_id, '-19'), in_acct,in_discount,0,in_receiptDateSN,concat('Discount on (', in_item_list,')'),in_facId,in_date,in_truck_no,in_waybill_no,qty);
                -- insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date, customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
                -- values (concat(in_version_id, '-19'), concat('Discount on (', in_item_list,')'),in_discount_head,0,in_discount ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
            insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`)
            values (in_facId,in_txn_date, concat('Discount on (', in_item_list,')'),in_discount_head,0,in_discount,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);
                
                
            -- INSERT INTO `client_entries`(`accountNo`, `version_id`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
            -- VALUES (in_acct,in_version_id,concat('Discount on (', in_item_list,')'),abs(in_discount),0,in_facId,in_mode_of_payment,in_receiptSN,0);
            INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
              
            VALUES (in_acct,concat('Discount on (', in_item_list,')'), 0,abs(in_discount), in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);
 
            
            update  `patientfileno` set balance= new_bal+in_discount where accountNo=in_acct AND facilityId=in_facId;
   
            END IF;


        end if;

        IF in_amount_paid > 0 THEN
           -- insert into account_entries (version_id, acct,dr,cr,reference_no,description,facilityId,createdAt,truckNo,waybillNo,quantity)
           -- values (concat(in_version_id, '-20'), in_acct,in_amount_paid,0,in_receiptDateSN,concat(in_payment_type,' for (', in_item_list, ')'),in_facId,in_date,in_truck_no,in_waybill_no,qty);

           --  insert into transactions (version_id, description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date,     customer_name,branch_name,quantity,txn_amount,customer_phone, customer_bank,customer_acc_no, bank_account,truckNo,waybillNo,salesFrom,item_code,expiry_date)
           --  values (concat(in_version_id, '-20'), concat(in_payment_type, ' for (', in_item_list, ')'),in_service_head,in_amount_paid,0,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date,in_customer_name,in_branch_name,qty,transaction_amount,cus_phone, cus_bank, cus_acc_no, bus_bank_acc_no,in_truck_no,in_waybill_no,in_salesFrom,in_item_code,in_expiry_date);
        --    insert into `transactions` (`facilityId`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `client_acct`, `patient_id`,`qty`,`unit_price`,`branch_name`)
        --     values (in_facId,in_txn_date, concat(in_payment_type, ' for (', in_item_list, ')'),in_service_head,in_amount_paid,0,userId, in_receiptDateSN, in_receiptSN, in_mode_of_payment,in_bank_name,'copleted',cus_acc_no,patientId,qty,in_price,_branch);
               
           -- Haltingx`
           
            -- INSERT INTO `client_entries`(`accountNo`, `version_id`, `description`, `dr`, `cr`, `facilityId`,mode_of_payment,receiptNo,quantity) 
            -- VALUES (in_acct,in_version_id,concat(in_payment_type,' for (', in_item_list, ')'),in_amount_paid,0,in_facId,in_mode_of_payment,in_receiptSN,0);
            INSERT INTO `account_entries`(`acct`,`description`, `dr`, `cr`, `facilityId`,  `mode_of_payment`, `reference_no`, `client_id`, `txn_status`, `quantity`)
            VALUES (in_acct,concat(in_payment_type,' for (', in_item_list, ')'),0, in_amount_paid, in_facId,in_mode_of_payment,in_receiptSN,patientId,'completed',qty);

            update  `patientfileno` set balance= new_bal+in_amount_paid where accountNo=in_acct AND facilityId=in_facId;
  
        END IF;

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_supplier_payment` (IN `in_facId` VARCHAR(50), IN `userId` VARCHAR(50), IN `in_acct` VARCHAR(50), IN `Amount_paid` INT, IN `in_receiptDateSN` VARCHAR(50), IN `in_receiptSN` VARCHAR(50), IN `in_mode_of_payment` VARCHAR(50), IN `sourceAcct` VARCHAR(50), IN `in_description` VARCHAR(100), IN `in_date` DATETIME, IN `in_payables_head` VARCHAR(50))   BEGIN

declare supplier_balance double;
    declare main_balance double;
    DECLARE balance_paid DOUBLE;
    
    select balance into supplier_balance from suppliersinfo where supplier_code=in_acct AND facilityId=in_facId;

    set main_balance = supplier_balance+Amount_paid;
    
    update suppliersinfo set balance= main_balance  where supplier_code=in_acct AND facilityId=in_facId;
    
    
     insert into supplier_entries (supplier_id,dr,cr,reference_no,facilityId,description)
           values (in_acct,0,Amount_paid,in_receiptDateSN,in_facId,in_description);
           
      
     -- insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,facilityId,createdAt,version_id)
        --   values (in_description,sourceAcct,0,Amount_paid,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,in_facId,in_date,in_version_id);
          
           
          -- insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,facilityId,createdAt,version_id)
         --  values (in_description,in_payables_head,0,abs(Amount_paid) ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,in_facId,in_date, concat(in_version_id,'-1'));
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `pharm_update_store` (IN `in_selling_price` FLOAT(11), IN `in_expiry_date` DATE, IN `in_drug_name` VARCHAR(100), IN `in_item_code` VARCHAR(100), IN `in_store` VARCHAR(100), IN `in_facilityId` VARCHAR(100), IN `in_balance` INT)   update pharm_store set selling_price=in_selling_price,balance=in_balance,drug_name=in_drug_name  WHERE expiry_date=in_expiry_date and item_code=in_item_code and store=in_store and facilityId=in_facilityId$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `previous_doc` (IN `in_patient_id` VARCHAR(20), IN `in_file_type` VARCHAR(50), IN `in_file_url` VARCHAR(200), IN `in_file_date` DATE, IN `query_type` VARCHAR(50))  NO SQL BEGIN 
IF query_type='insert' THEN
INSERT INTO previous_doc (patient_id,file_type,file_url,file_date) VALUES(in_patient_id,in_file_type,in_file_url,in_file_date);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `psc_dashboard` (IN `in_query_type` VARCHAR(50), IN `in_date_from` VARCHAR(50), IN `in_date_to` VARCHAR(50), IN `in_facilityid` VARCHAR(50))   BEGIN
    -- Revenue trend data (daily breakdown)
    IF in_query_type = 'revenue_trend' THEN
        IF in_facilityid = 'all' THEN
            SELECT 
                DATE(transaction_date) AS date,
                SUM(amount) AS total_amount,
                SUM(CASE WHEN service_type = 'CONSULTATION' THEN amount ELSE 0 END) AS consultation_amount,
                SUM(CASE WHEN service_type = 'LAB' THEN amount ELSE 0 END) AS lab_amount,
                SUM(CASE WHEN service_type = 'PHARMACY' THEN amount ELSE 0 END) AS pharmacy_amount,
                SUM(CASE WHEN service_type = 'REGISTRATION' THEN amount ELSE 0 END) AS registration_amount
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY DATE(transaction_date)
            ORDER BY DATE(transaction_date);
        ELSE
            SELECT 
                DATE(transaction_date) AS date,
                SUM(amount) AS total_amount,
                SUM(CASE WHEN service_type = 'CONSULTATION' THEN amount ELSE 0 END) AS consultation_amount,
                SUM(CASE WHEN service_type = 'LAB' THEN amount ELSE 0 END) AS lab_amount,
                SUM(CASE WHEN service_type = 'PHARMACY' THEN amount ELSE 0 END) AS pharmacy_amount,
                SUM(CASE WHEN service_type = 'REGISTRATION' THEN amount ELSE 0 END) AS registration_amount
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY DATE(transaction_date)
            ORDER BY DATE(transaction_date);
        END IF;
    
    -- Service type breakdown
    ELSEIF in_query_type = 'by_service_type' THEN
        IF in_facilityid = 'all' THEN
            SELECT 
                service_type,
                SUM(amount) AS total_amount,
                COUNT(*) AS transaction_count,
                (SUM(amount) / (SELECT SUM(amount) FROM pending_txn WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to)) * 100 AS percentage
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY service_type
            ORDER BY total_amount DESC;
        ELSE
            SELECT 
                service_type,
                SUM(amount) AS total_amount,
                COUNT(*) AS transaction_count,
                (SUM(amount) / (SELECT SUM(amount) FROM pending_txn WHERE facilityId = in_facilityid AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to)) * 100 AS percentage
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY service_type
            ORDER BY total_amount DESC;
        END IF;
    
    -- Top services by revenue
    ELSEIF in_query_type = 'top_services' THEN
        IF in_facilityid = 'all' THEN
            SELECT 
                description,
                service_type,
                SUM(amount) AS total_amount,
                COUNT(*) AS transaction_count
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY description, service_type
            ORDER BY total_amount DESC
            LIMIT 10;
        ELSE
            SELECT 
                description,
                service_type,
                SUM(amount) AS total_amount,
                COUNT(*) AS transaction_count
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY description, service_type
            ORDER BY total_amount DESC
            LIMIT 10;
        END IF;
    
    -- Payment methods breakdown
    ELSEIF in_query_type = 'payment_methods' THEN
        IF in_facilityid = 'all' THEN
            SELECT 
                mode_of_payment,
                SUM(amount) AS total_amount,
                COUNT(*) AS transaction_count,
                (SUM(amount) / (SELECT SUM(amount) FROM pending_txn WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to)) * 100 AS percentage
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to
              AND mode_of_payment IS NOT NULL
            GROUP BY mode_of_payment
            ORDER BY total_amount DESC;
        ELSE
            SELECT 
                mode_of_payment,
                SUM(amount) AS total_amount,
                COUNT(*) AS transaction_count,
                (SUM(amount) / (SELECT SUM(amount) FROM pending_txn WHERE facilityId = in_facilityid AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to)) * 100 AS percentage
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to
              AND mode_of_payment IS NOT NULL
            GROUP BY mode_of_payment
            ORDER BY total_amount DESC;
        END IF;
    
    -- Patient types breakdown
    ELSEIF in_query_type = 'patient_types' THEN
        IF in_facilityid = 'all' THEN
            SELECT 
                patient_type,
                SUM(amount) AS total_amount,
                COUNT(*) AS transaction_count,
                (SUM(amount) / (SELECT SUM(amount) FROM pending_txn WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to)) * 100 AS percentage
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to
              AND patient_type IS NOT NULL
            GROUP BY patient_type
            ORDER BY total_amount DESC;
        ELSE
            SELECT 
                patient_type,
                SUM(amount) AS total_amount,
                COUNT(*) AS transaction_count,
                (SUM(amount) / (SELECT SUM(amount) FROM pending_txn WHERE facilityId = in_facilityid AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to)) * 100 AS percentage
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to
              AND patient_type IS NOT NULL
            GROUP BY patient_type
            ORDER BY total_amount DESC;
        END IF;
    
    -- Summary statistics (for the main dashboard cards)
    ELSEIF in_query_type = 'summary' THEN
        IF in_facilityid = 'all' THEN
            SELECT 
                SUM(amount) AS total_revenue,
                COUNT(DISTINCT patient_id) AS patient_count,
                COUNT(*) AS transaction_count,
                AVG(amount) AS average_transaction,
                SUM(CASE WHEN service_type = 'CONSULTATION' THEN amount ELSE 0 END) AS consultation_revenue,
                SUM(CASE WHEN service_type = 'LAB' THEN amount ELSE 0 END) AS lab_revenue,
                SUM(CASE WHEN service_type = 'PHARMACY' THEN amount ELSE 0 END) AS pharmacy_revenue,
                SUM(CASE WHEN service_type = 'REGISTRATION' THEN amount ELSE 0 END) AS registration_revenue,
                (SELECT SUM(amount) FROM pending_txn 
                 WHERE DATE(transaction_date) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)) AS previous_day_revenue,
                (SELECT SUM(amount) FROM pending_txn 
                 WHERE DATE(transaction_date) BETWEEN DATE_SUB(in_date_from, INTERVAL DATEDIFF(in_date_to, in_date_from) DAY) 
                 AND DATE_SUB(in_date_from, INTERVAL 1 DAY)) AS previous_period_revenue
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to;
        ELSE
            SELECT 
                SUM(amount) AS total_revenue,
                COUNT(DISTINCT patient_id) AS patient_count,
                COUNT(*) AS transaction_count,
                AVG(amount) AS average_transaction,
                SUM(CASE WHEN service_type = 'CONSULTATION' THEN amount ELSE 0 END) AS consultation_revenue,
                SUM(CASE WHEN service_type = 'LAB' THEN amount ELSE 0 END) AS lab_revenue,
                SUM(CASE WHEN service_type = 'PHARMACY' THEN amount ELSE 0 END) AS pharmacy_revenue,
                SUM(CASE WHEN service_type = 'REGISTRATION' THEN amount ELSE 0 END) AS registration_revenue,
                (SELECT SUM(amount) FROM pending_txn 
                 WHERE facilityId = in_facilityid 
                 AND DATE(transaction_date) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)) AS previous_day_revenue,
                (SELECT SUM(amount) FROM pending_txn 
                 WHERE facilityId = in_facilityid 
                 AND DATE(transaction_date) BETWEEN DATE_SUB(in_date_from, INTERVAL DATEDIFF(in_date_to, in_date_from) DAY) 
                 AND DATE_SUB(in_date_from, INTERVAL 1 DAY)) AS previous_period_revenue
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `psc_dashboardb4` (IN `in_query_type` VARCHAR(50), IN `in_date_from` VARCHAR(50), IN `in_date_to` VARCHAR(50), IN `in_facilityid` VARCHAR(50))   BEGIN
    IF in_query_type = 'revenue_trend' THEN
        -- Get daily revenue trend for the selected period
        IF in_facilityid = 'all' THEN
            SELECT 
                DATE(transaction_date) AS date,
                SUM(amount) AS amount,
                COUNT(DISTINCT transaction_id) AS transactions,
                COUNT(DISTINCT patient_id) AS patients
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY DATE(transaction_date)
            ORDER BY DATE(transaction_date);
        ELSE
            SELECT 
                DATE(transaction_date) AS date,
                SUM(amount) AS amount,
                COUNT(DISTINCT transaction_id) AS transactions,
                COUNT(DISTINCT patient_id) AS patients
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY DATE(transaction_date)
            ORDER BY DATE(transaction_date);
        END IF;
        
    ELSEIF in_query_type = 'by_service_type' THEN
        -- Get revenue breakdown by service type
        IF in_facilityid = 'all' THEN
            SELECT 
                service_type,
                SUM(amount) AS amount,
                COUNT(*) AS transaction_count,
                (SUM(amount) / (SELECT SUM(amount) FROM pending_txn 
                                 WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to)) * 100 AS percentage
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY service_type
            ORDER BY amount DESC;
        ELSE
            SELECT 
                service_type,
                SUM(amount) AS amount,
                COUNT(*) AS transaction_count,
                (SUM(amount) / (SELECT SUM(amount) FROM pending_txn 
                                 WHERE facilityId = in_facilityid 
                                   AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to)) * 100 AS percentage
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY service_type
            ORDER BY amount DESC;
        END IF;
        
    ELSEIF in_query_type = 'top_services' THEN
        -- Get top 5 services by revenue
        IF in_facilityid = 'all' THEN
            SELECT 
                description,
                SUM(amount) AS amount,
                COUNT(*) AS transaction_count
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY description
            ORDER BY amount DESC
            LIMIT 5;
        ELSE
            SELECT 
                description,
                SUM(amount) AS amount,
                COUNT(*) AS transaction_count
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY description
            ORDER BY amount DESC
            LIMIT 5;
        END IF;
        
    ELSEIF in_query_type = 'payment_methods' THEN
        -- Get revenue breakdown by payment method
        IF in_facilityid = 'all' THEN
            SELECT 
                IFNULL(mode_of_payment, 'UNKNOWN') AS payment_method,
                SUM(amount) AS amount,
                COUNT(*) AS transaction_count
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY mode_of_payment
            ORDER BY amount DESC;
        ELSE
            SELECT 
                IFNULL(mode_of_payment, 'UNKNOWN') AS payment_method,
                SUM(amount) AS amount,
                COUNT(*) AS transaction_count
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY mode_of_payment
            ORDER BY amount DESC;
        END IF;
        
    ELSEIF in_query_type = 'patient_types' THEN
        -- Get revenue breakdown by patient type
        IF in_facilityid = 'all' THEN
            SELECT 
                IFNULL(patient_type, 'UNKNOWN') AS patient_type,
                SUM(amount) AS amount,
                COUNT(DISTINCT patient_id) AS patient_count
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY patient_type
            ORDER BY amount DESC;
        ELSE
            SELECT 
                IFNULL(patient_type, 'UNKNOWN') AS patient_type,
                SUM(amount) AS amount,
                COUNT(DISTINCT patient_id) AS patient_count
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to
            GROUP BY patient_type
            ORDER BY amount DESC;
        END IF;
        
    ELSEIF in_query_type = 'summary' THEN
        -- Get summary statistics for the dashboard
        IF in_facilityid = 'all' THEN
            SELECT 
                SUM(amount) AS total_revenue,
                COUNT(DISTINCT transaction_id) AS total_transactions,
                COUNT(DISTINCT patient_id) AS total_patients,
                AVG(amount) AS avg_transaction_value,
                (SELECT SUM(amount) FROM pending_txn 
                 WHERE DATE(transaction_date) = CURDATE()) AS today_revenue,
                (SELECT COUNT(DISTINCT transaction_id) FROM pending_txn 
                 WHERE DATE(transaction_date) = CURDATE()) AS today_transactions
            FROM `pending_txn`
            WHERE DATE(transaction_date) BETWEEN in_date_from AND in_date_to;
        ELSE
            SELECT 
                SUM(amount) AS total_revenue,
                COUNT(DISTINCT transaction_id) AS total_transactions,
                COUNT(DISTINCT patient_id) AS total_patients,
                AVG(amount) AS avg_transaction_value,
                (SELECT SUM(amount) FROM pending_txn 
                 WHERE facilityId = in_facilityid 
                   AND DATE(transaction_date) = CURDATE()) AS today_revenue,
                (SELECT COUNT(DISTINCT transaction_id) FROM pending_txn 
                 WHERE facilityId = in_facilityid 
                   AND DATE(transaction_date) = CURDATE()) AS today_transactions
            FROM `pending_txn`
            WHERE facilityId = in_facilityid 
              AND DATE(transaction_date) BETWEEN in_date_from AND in_date_to;
        END IF;
        
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `query_lab_setup` (IN `in_head` INT, IN `facId` VARCHAR(50), IN `in_query_type` VARCHAR(50), IN `in_subhead` INT, IN `in_description` VARCHAR(100), IN `in_label_name` VARCHAR(50), IN `in_no_of_labels` INT, IN `in_unit` VARCHAR(10), IN `in_range_from` VARCHAR(10), IN `in_range_to` VARCHAR(10), IN `in_report_type` VARCHAR(50), IN `in_form_mode` VARCHAR(50), IN `in_unit_name` VARCHAR(50), IN `in_specimen` VARCHAR(50), IN `in_to_collect_sample` VARCHAR(5), IN `in_to_be_analyzed` VARCHAR(5), IN `in_to_be_reported` VARCHAR(5), IN `in_upload_doc` VARCHAR(5), IN `in_label_type` VARCHAR(50), IN `in_print_type` VARCHAR(50), IN `in_price` INT(30), IN `in_old_price` INT)  NO SQL IF in_query_type = 'next subhead' THEN
	SELECT ifnull(MAX(subhead)+ 1, concat(in_head,'1'))  as next_code FROM lab_setup WHERE head=in_head AND facilityId=facId;
ELSEIF in_query_type = 'report_type' THEN
	SELECT DISTINCT report_type from lab_setup WHERE report_type is not null;
    ELSEIF in_query_type ="update_lab_setup_account" THEN
update lab_setup set price=in_price, old_price=in_old_price where subhead=in_subhead;
ELSEIF in_query_type = 'new_test' THEN
	INSERT INTO lab_setup (head,subhead,description, label_name, noOfLabels, unit, range_from, range_to, report_type,facilityId, specimen, collect_sample, to_be_analyzed, to_be_reported, upload_doc) VALUES (in_head,in_subhead,in_description, in_label_name, in_no_of_labels, in_unit, in_range_from, in_range_to, in_report_type, facId,in_specimen, in_to_collect_sample, in_to_be_analyzed, in_to_be_reported, in_upload_doc);
ELSEIF in_query_type = 'update_test' THEN
UPDATE lab_setup SET head=in_head, description=in_description, label_name=in_label_name, noOfLabels=in_no_of_labels, unit=in_unit, range_from=in_range_from, range_to=in_range_to, report_type=in_report_type, specimen=in_specimen, collect_sample=in_to_collect_sample, to_be_analyzed=in_to_be_analyzed, to_be_reported=in_to_be_reported, upload_doc=in_upload_doc WHERE subhead=in_subhead AND facilityId=facId;
ELSEIF in_query_type = 'delete' THEN 
	DELETE FROM lab_setup WHERE subhead = in_subhead AND facilityId=facId;
ELSEIF in_query_type = 'code_setup' THEN
	UPDATE lab_setup SET label_type=in_label_type, print_type=in_print_type WHERE (subhead=in_subhead OR head=in_subhead) AND facilityId=facId;
ELSEIF in_query_type = 'test_info' THEN
	SELECT * FROM lab_setup WHERE subhead=in_subhead;
ELSEIF in_query_type = 'group_list' THEN
SELECT * FROM lab_setup WHERE subhead IN (SELECT DISTINCT head FROM lab_setup);
ELSEIF in_query_type = 'unit_list' THEN
	IF in_head = 'all' THEN
		SELECT DISTINCT unit_name,unit_code FROM lab_setup;
    ELSE 
    	SELECT DISTINCT unit_name,unit_code FROM lab_setup WHERE lab_code = in_head;
    END IF;
ELSEIF in_query_type = 'department_list' THEN
	SELECT * FROM lab_setup WHERE head=1000;
ELSEIF in_query_type = 'Barcode Setup' THEN
	IF in_form_mode = 'Stand Alone Test' THEN 
    	SELECT * FROM lab_setup WHERE label_type='single';
    ELSE 
    	SELECT * FROM lab_setup WHERE label_type IN ('grouped', 'singular_group', 'grouped_single');
    END IF;
   	ELSEIF in_query_type = 'by_group' THEN
    call get_lab_setup_account('','', in_subhead, facId);
    ELSEIF in_query_type = 'by_head' THEN
    	SELECT * FROM lab_setup WHERE head=in_head;
    ELSEIF in_query_type = 'all' THEN
    	SELECT * FROM lab_setup WHERE facilityId=facId; #AND old_price = '';
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `query_only_consultation` (IN `query_type` VARCHAR(30))   BEGIN
SELECT * FROM `consultations` WHERE consultation_notes LIKE query_type LIMIT 100;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `save_operation_note` (IN `op_date` VARCHAR(30), IN `patient_id` VARCHAR(10), IN `diagnosis` VARCHAR(150), IN `surgery` VARCHAR(150), IN `surgeons` VARCHAR(150), IN `anesthetist` VARCHAR(80), IN `anesthetic` VARCHAR(20), IN `scrubNurse` VARCHAR(30), IN `remarks` VARCHAR(50), IN `name` VARCHAR(100), IN `pintsGiven` VARCHAR(10), IN `bloodLoss` VARCHAR(15), IN `intraOpAntibiotics` VARCHAR(20), IN `intraOpFindings` VARCHAR(2000), IN `procedureNotes` VARCHAR(2000), IN `pathologyRequest` VARCHAR(200), IN `postOpOrder` VARCHAR(1000), IN `facId` VARCHAR(50), IN `uid` VARCHAR(50), IN `in_query_type` VARCHAR(50), IN `in_report_type` VARCHAR(50))   BEGIN
    DECLARE p_name VARCHAR(300);

    IF in_query_type = 'new' THEN
        SELECT concat(surname, ' ', firstname) INTO p_name FROM patientrecords WHERE patientrecords.id = patient_id;

        INSERT INTO operationnotes(
            date,
            patientId,
            diagnosis,
            surgery,
            surgeons,
            anesthetist,
            anesthetic,
            scrubNurse,
            remarks,
            NAME,
            pintsGiven,
            bloodLoss,
            intraOpAntibiotics,
            intraOpFindings,
            procedureNotes,
            pathologyRequest,
            postOpOrder,
            facilityId,
            uuid
        )
                VALUES(
            op_date,
            patient_id,
            diagnosis,
            surgery,
            surgeons,
            anesthetist,
            anesthetic,
            scrubNurse,
            remarks,
            p_name,
            pintsGiven,
            bloodLoss,
            intraOpAntibiotics,
            intraOpFindings,
            procedureNotes,
            pathologyRequest,
            postOpOrder,
            facId,
            uid
                );
    ELSEIF in_query_type = 'list by patient' THEN
        IF in_report_type = 'by_date' THEN
                SELECT * FROM operationnotes WHERE patientId=patient_id AND date(createdAt) = op_date AND facilityId = facId;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `save_pending_lab_tx` (IN `in_query_type` VARCHAR(50), IN `in_account` INT, IN `in_description` VARCHAR(100), IN `in_group_head` VARCHAR(20), IN `in_price` INT, IN `in_test` VARCHAR(20), IN `in_req_id` VARCHAR(50), IN `in_status` VARCHAR(10))  NO SQL IF in_query_type = 'new' THEN
	INSERT INTO pending_lab_txn (account, description,group_head,price,test,request_id,status) VALUES (in_account,in_description,in_group_head,in_price,in_test,in_req_id,in_status);
ELSEIF in_query_type='by_req' THEN
	SELECT account, description,test_group as group_head,price, test,request_id,status FROM lab_requisition WHERE request_id=in_req_id and price > 0;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `save_vitals` (IN `in_query_type` VARCHAR(20), IN `in_b_temp` VARCHAR(10), IN `in_pulse` VARCHAR(10), IN `in_b_p` VARCHAR(10), IN `in_resp_rate` VARCHAR(10), IN `in_fasting` VARCHAR(10), IN `in_random` VARCHAR(10), IN `in_user` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `in_patient_id` VARCHAR(50), IN `in_created_at` VARCHAR(20), IN `in_spo2` VARCHAR(50))  NO SQL IF in_query_type = 'new' THEN
        INSERT INTO vital_signs (body_temp, pulse_rate,  blood_pressure, respiratory_rate,
  fasting_blood_sugar, random_blood_sugar, created_by, facilityId, patient_id,created_at,spo2) VALUES (in_b_temp,in_pulse,in_b_p,in_resp_rate, in_fasting, in_random, in_user,in_facId, in_patient_id, in_created_at,in_spo2);
ELSEIF in_query_type = 'list by patient' THEN
        SELECT * FROM vital_signs WHERE patient_id=in_patient_id ORDER BY created_at DESC;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `service_transaction` (IN `p_facilityId` VARCHAR(50), IN `p_transaction_date` DATE, IN `p_description` VARCHAR(225), IN `p_acct` VARCHAR(100), IN `p_sourceAcct` VARCHAR(20), IN `p_debit` INT, IN `p_credit` INT, IN `p_unit_price` DOUBLE, IN `p_enteredBy` VARCHAR(20), IN `p_receiptDateSN` VARCHAR(50), IN `p_receiptNo` VARCHAR(50), IN `p_modeOfPayment` VARCHAR(50), IN `p_bank_name` VARCHAR(50), IN `p_status` VARCHAR(30), IN `p_approvedBy` VARCHAR(20), IN `p_paymentStatus` VARCHAR(11), IN `p_client_acct` VARCHAR(200), IN `p_patient_id` VARCHAR(50), IN `p_qty` VARCHAR(20), IN `p_branch_name` VARCHAR(30))   BEGIN
    INSERT INTO transactions (
        facilityId,
        createdAt,
        transaction_date,
        description,
        acct,
        debit,
        credit,
        unit_price,
        enteredBy,
        receiptDateSN,
        receiptNo,
        modeOfPayment,
        bank_name,
        status,
        approvedBy,
        paymentStatus,
        client_acct,
        patient_id,
        qty,
        branch_name
    )
    VALUES (
        p_facilityId,
        NOW(),
        p_transaction_date,
        p_description,
        p_acct,
        0,
        p_credit,
        p_unit_price,
        p_enteredBy,
        p_receiptDateSN,
        p_receiptNo,
        p_modeOfPayment,
        p_bank_name,
        p_status,
        p_approvedBy,
        p_paymentStatus,
        p_client_acct,
        p_patient_id,
        p_qty,
        p_branch_name
    );

    -- Insert Debit Entry (Service Provided)
    INSERT INTO transactions (
        facilityId,
        createdAt,
        transaction_date,
        description,
        acct,
        debit,
        credit,
        unit_price,
        enteredBy,
        receiptDateSN,
        receiptNo,
        modeOfPayment,
        bank_name,
        status,
        approvedBy,
        paymentStatus,
        client_acct,
        patient_id,
        qty,
        branch_name
    )
    VALUES (
        p_facilityId,
        NOW(),
        p_transaction_date,
        p_description,
        p_sourceAcct,
        p_debit,
        0,
        p_unit_price,
        p_enteredBy,
        p_receiptDateSN,
        p_receiptNo,
        p_modeOfPayment,
        p_bank_name,
        p_status,
        p_approvedBy,
        p_paymentStatus,
        p_client_acct,
        p_patient_id,
        p_qty,
        p_branch_name
    );
    
    -- updating statss
   UPDATE pending_txn set tx_status="paid" where transaction_id=p_receiptDateSN;

    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `service_transaction3` (IN `in_description` VARCHAR(1000), IN `in_acct` INT, IN `service_amount` INT, IN `in_receiptDateSN` VARCHAR(50), IN `in_receiptSN` VARCHAR(50), IN `in_mode_of_payment` VARCHAR(20), IN `patientId` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `sourceAcct` VARCHAR(50), IN `userId` VARCHAR(50), IN `in_service_head` VARCHAR(50), IN `txnType` VARCHAR(10), IN `in_date` DATETIME, IN `in_payables_head` VARCHAR(50), IN `in_recievables_head` VARCHAR(50), IN `in_bank_name` VARCHAR(50), IN `in_txn_date` DATE, IN `in_discount` INT, IN `in_discount_head` VARCHAR(50), IN `txn_status` VARCHAR(30), IN `in_payables_head_name` VARCHAR(150), IN `in_recievables_head_name` VARCHAR(150), IN `in_discount_head_name` VARCHAR(150), IN `sourceAcct_name` VARCHAR(150), IN `in_service_head_name` VARCHAR(150), IN `in_patient_name` VARCHAR(150))   BEGIN
	declare client_balance int;
	declare main_balance int;
    declare receivable int;
    DECLARE instant_balance int;
    DECLARE cash_amount int;
   
--    declare service_description varchar(200);
	select balance into client_balance  from patientfileno where accountNo=in_acct AND facilityId=in_facId;
	
    set cash_amount = service_amount - in_discount;
    set main_balance = client_balance-cash_amount;
    set receivable  = cash_amount-client_balance;
    set instant_balance = client_balance + cash_amount;
   
    
    IF txnType = 'insta' THEN
    
    	update patientfileno set balance= instant_balance where accountNo=in_acct AND facilityId=in_facId;
        
        insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);
    
    	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

            insert into transactions3 (description,acct,acc_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,sourceAcct,sourceAcct_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head, in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;
    
    ELSE

        -- IF the service amount is equal to the customer account balance (initial deposit amount)
        -- IF after the service amount is deducted, the client is still a debtor,

        if main_balance  > 0  then

            update patientfileno set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head, in_payables_head_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,accName,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head, in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

        elseif main_balance < 0 then
            update patientfileno set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);


            if client_balance = 0 then
            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,in_recievables_head_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

            -- IF client had some amount in their deposit
        elseif client_balance > 0  then

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head,in_payables_head_name,abs(client_balance),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,in_recievables_head_name,abs(receivable),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;
            
        elseif client_balance < 0  then

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,in_recievables_head_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

            end if;
        elseif  main_balance = 0 then

            update patientfileno set balance= main_balance  where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);


            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head,in_payables_head_name,abs(client_balance),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

        -- IF the service amount is less the customer account balance
        end if;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `service_transaction4` (IN `in_description` VARCHAR(1000), IN `in_acct` INT, IN `service_amount` INT, IN `in_receiptDateSN` VARCHAR(50), IN `in_receiptSN` VARCHAR(50), IN `in_mode_of_payment` VARCHAR(20), IN `patientId` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `sourceAcct` VARCHAR(50), IN `userId` VARCHAR(50), IN `in_service_head` VARCHAR(50), IN `txnType` VARCHAR(10), IN `in_date` DATETIME, IN `in_payables_head` VARCHAR(50), IN `in_recievables_head` VARCHAR(50), IN `in_bank_name` VARCHAR(50), IN `in_txn_date` DATE, IN `in_discount` INT, IN `in_discount_head` VARCHAR(50), IN `txn_status` VARCHAR(30), IN `in_payables_head_name` VARCHAR(150), IN `in_recievables_head_name` VARCHAR(150), IN `in_discount_head_name` VARCHAR(150), IN `sourceAcct_name` VARCHAR(150), IN `in_service_head_name` VARCHAR(150), IN `in_patient_name` VARCHAR(150), IN `in_id` VARCHAR(50), IN `in_service_type` VARCHAR(100), IN `in_discout_amount` INT, IN `discount_desc` VARCHAR(200), IN `in_item_amount` INT, IN `in_amountPaid` INT, IN `in_patient_id` VARCHAR(50))   BEGIN
	declare client_balance int;
	declare main_balance int;
    declare receivable int;
    DECLARE instant_balance int;
    DECLARE cash_amount int;
   
--    declare service_description varchar(200);
	select balance into client_balance  from patientfileno where accountNo=in_acct AND facilityId=in_facId;
	
    set cash_amount = service_amount - in_discount;
    set main_balance = client_balance-cash_amount;
    set receivable  = cash_amount-client_balance;
    set instant_balance = client_balance + cash_amount;
   
    
    IF txnType = 'insta' THEN
    
    	update patientfileno set balance= instant_balance where accountNo=in_acct AND facilityId=in_facId;
        
        insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);
    
    	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

            insert into transactions3 (description,acct,acc_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,sourceAcct,sourceAcct_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head, in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;
    
    ELSE

        -- IF the service amount is equal to the customer account balance (initial deposit amount)
        -- IF after the service amount is deducted, the client is still a debtor,

        if main_balance  > 0  then

            update patientfileno set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head, in_payables_head_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,accName,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head, in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

        elseif main_balance < 0 then
            update patientfileno set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);


            if client_balance = 0 then
            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,in_recievables_head_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

            -- IF client had some amount in their deposit
        elseif client_balance > 0  then

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head,in_payables_head_name,abs(client_balance),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,in_recievables_head_name,abs(receivable),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;
            
        elseif client_balance < 0  then

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,in_recievables_head_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

            end if;
        elseif  main_balance = 0 then

            update patientfileno set balance= main_balance  where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);


            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head,in_payables_head_name,abs(client_balance),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

        -- IF the service amount is less the customer account balance
        end if;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `service_transaction5` (IN `in_description` VARCHAR(1000), IN `in_acct` INT, IN `service_amount` INT, IN `in_receiptDateSN` VARCHAR(50), IN `in_receiptSN` VARCHAR(50), IN `in_mode_of_payment` VARCHAR(20), IN `patientId` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `sourceAcct` VARCHAR(50), IN `userId` VARCHAR(50), IN `in_service_head` VARCHAR(50), IN `txnType` VARCHAR(10), IN `in_date` DATETIME, IN `in_payables_head` VARCHAR(50), IN `in_recievables_head` VARCHAR(50), IN `in_bank_name` VARCHAR(50), IN `in_txn_date` DATE, IN `in_discount` INT, IN `in_discount_head` VARCHAR(50), IN `txn_status` VARCHAR(30), IN `in_payables_head_name` VARCHAR(150), IN `in_recievables_head_name` VARCHAR(150), IN `in_discount_head_name` VARCHAR(150), IN `sourceAcct_name` VARCHAR(150), IN `in_service_head_name` VARCHAR(150), IN `in_patient_name` VARCHAR(150), IN `in_id` VARCHAR(50), IN `in_service_type` VARCHAR(100), IN `in_discout_amount` INT, IN `discount_desc` VARCHAR(200), IN `in_item_amount` INT, IN `in_amountPaid` INT, IN `in_patient_id` VARCHAR(50), IN `in_expiry_date` DATE, IN `in_branch_location` VARCHAR(50), IN `in_item_code` VARCHAR(50), IN `in_qty_out` INT)   BEGIN
	declare client_balance int;
	declare main_balance int;
    declare receivable int;
    DECLARE instant_balance int;
    DECLARE cash_amount int;
   
--    declare service_description varchar(200);
	select balance into client_balance  from patientfileno where accountNo=in_acct AND facilityId=in_facId;
	
    set cash_amount = service_amount - in_discount;
    set main_balance = client_balance-cash_amount;
    set receivable  = cash_amount-client_balance;
    set instant_balance = client_balance + cash_amount;
   
    
    IF txnType = 'insta' THEN
    
    	update patientfileno set balance= instant_balance where accountNo=in_acct AND facilityId=in_facId;
        
        insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);
    
    	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

            insert into transactions3 (description,acct,acc_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,sourceAcct,sourceAcct_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head, in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;
    
    ELSE

        -- IF the service amount is equal to the customer account balance (initial deposit amount)
        -- IF after the service amount is deducted, the client is still a debtor,

        if main_balance  > 0  then

            update patientfileno set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head, in_payables_head_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,accName,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head, in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

        elseif main_balance < 0 then
            update patientfileno set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);


            if client_balance = 0 then
            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,in_recievables_head_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

            -- IF client had some amount in their deposit
        elseif client_balance > 0  then

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head,in_payables_head_name,abs(client_balance),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,in_recievables_head_name,abs(receivable),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;
            
        elseif client_balance < 0  then

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,in_recievables_head_name,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

            end if;
        elseif  main_balance = 0 then

            update patientfileno set balance= main_balance  where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date);

            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,in_service_head_name,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);


            insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head,in_payables_head_name,abs(client_balance),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
            	insert into transactions3 (description,acct,acct_name,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount_head_name,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

        -- IF the service amount is less the customer account balance
        end if;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `service_transaction_pharm` (IN `in_query_type` VARCHAR(50), IN `in_txn_id` VARCHAR(50), IN `in_cashier_id` VARCHAR(50), IN `in_mode_of_payment` VARCHAR(50))   BEGIN
    	if in_query_type = 'paid' THEN
        	UPDATE pending_txn SET tx_status='paid', cashier_id=in_cashier_id, 
            transaction_date = now(), mode_of_payment=in_mode_of_payment where transaction_id = in_txn_id;
        END IF;
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `service_transaction_xx` (IN `in_description` VARCHAR(1000), IN `in_acct` INT, IN `service_amount` INT, IN `in_receiptDateSN` VARCHAR(50), IN `in_receiptSN` VARCHAR(50), IN `in_mode_of_payment` VARCHAR(20), IN `patientId` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `sourceAcct` VARCHAR(50), IN `userId` VARCHAR(50), IN `in_service_head` VARCHAR(50), IN `txnType` VARCHAR(10), IN `in_date` DATETIME, IN `in_payables_head` VARCHAR(50), IN `in_recievables_head` VARCHAR(50), IN `in_bank_name` VARCHAR(50), IN `in_txn_date` DATE, IN `in_discount` INT, IN `in_discount_head` VARCHAR(50), IN `_txn_status` VARCHAR(30), IN `amount_paid` INT, IN `services_list` VARCHAR(90))   BEGIN

    declare client_balance int;
    declare main_balance int;
    declare receivable int;
    DECLARE instant_balance int;
    DECLARE cash_amount int;
   
--    declare service_description varchar(200);
    select balance into client_balance  from patientfileno where accountNo=in_acct AND facilityId=in_facId;
    
    set cash_amount = service_amount - in_discount;
    set main_balance = client_balance-cash_amount;
    set receivable  = cash_amount-client_balance;
    set instant_balance = client_balance + cash_amount;
   
    
    IF txnType = 'insta' THEN
    
        -- update patientfileno set balance= instant_balance where accountNo=in_acct AND facilityId=in_facId;
        
     --   insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt,client_id,txn_status)
        --    values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date,patientId,_txn_status);
    
        insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

#insert into transactions 
#  (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,
#                          client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
 #           values (in_description,'500011',0,service_amount,in_receiptDateSN,in_receiptSN,
  #                  in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);


            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,sourceAcct,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
                insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;
    
    ELSE

        -- IF the service amount is equal to the customer account balance (initial deposit amount)
        -- IF after the service amount is deducted, the client is still a debtor,

        if main_balance  > 0  then

            update patientfileno set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt,client_id,txn_status)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date,patientId,_txn_status);

            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

# insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,
 #                         client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
  #          values (in_description,'500011',0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
  #                  userId,in_acct,patientId,in_facId,in_date,in_bank_name);

            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
                insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

        elseif main_balance < 0 then
            update patientfileno set balance= main_balance where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt,client_id,txn_status)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date,patientId,_txn_status);

            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

#insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,
 #                         enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
  #          values (in_description,'500011',0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,
   #                 userId,in_acct,patientId,in_facId,in_date,in_bank_name);

            if client_balance = 0 then
            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
                insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

            -- IF client had some amount  in their deposit
        elseif client_balance > 0  then

            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head,abs(client_balance),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,abs(receivable),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
                insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;
            
        elseif client_balance < 0  then

            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_recievables_head,abs(cash_amount),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
                insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

            end if;
        elseif  main_balance = 0 then

            update patientfileno set balance= main_balance  where accountNo=in_acct AND facilityId=in_facId;

            insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt,client_id,txn_status)
            values (in_acct,0,service_amount,in_receiptDateSN,in_description,in_facId,in_date,patientId,_txn_status);

            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,0,service_amount,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);

#insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,
 #                         enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name)
  #          values (in_description,'500011',0,service_amount,in_receiptDateSN,in_receiptSN,
   #                 in_mode_of_payment,userId,in_acct,patientId,in_facId,in_dat,in_bank_name,in_txn_date);

            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_payables_head,abs(client_balance),0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            
            IF in_discount > 0 THEN
                insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_discount_head,in_discount,0 ,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
            END IF;

        -- IF the service amount is less the customer account balance
        end if;

    END IF;

    IF amount_paid > 0 THEN
            insert into transactions (description,acct,debit,credit,receiptDateSN,receiptNo,modeOfPayment,enteredBy,client_acct,patient_id,facilityId,createdAt,bank_name,transaction_date)
            values (in_description,in_service_head,0,amount_paid,in_receiptDateSN,in_receiptSN,in_mode_of_payment,userId,in_acct,patientId,in_facId,in_date,in_bank_name,in_txn_date);
  insert into account_entries (acct,dr,cr,reference_no,description,facilityId,createdAt,client_id,txn_status)
   values (in_acct,amount_paid,0,in_receiptDateSN,in_description,in_facId,in_date,patientId,_txn_status);
 update patientfileno set balance= (client_balance + amount_paid ) where accountNo=in_acct AND facilityId=in_facId;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `surgeon` (IN `in_name` VARCHAR(100), IN `in_type` VARCHAR(100), IN `in_id` VARCHAR(11), IN `facId` VARCHAR(50), IN `query_type` VARCHAR(20))  NO SQL BEGIN
IF query_type = 'select' THEN
SELECT name, type, id FROM surgeons_list WHERE facilityId =facId;
ELSEIF query_type = 'by_type' THEN
SELECT name, type, id FROM surgeons_list WHERE type=in_type AND facilityId =facId;
ELSEIF  query_type = 'update' THEN
UPDATE surgeons_list SET name=in_name, type=in_type where id=in_id and facilityId =facId;
ELSEIF  query_type = 'delete' THEN
DELETE from surgeons_list WHERE id=in_id and facilityId =facId;
ELSEIF  query_type = 'select_one' THEN
SELECT * from surgeons_list WHERE id=in_id and facilityId =facId;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `surgical_note` (IN `in_template` VARCHAR(4324), IN `in_patient_name` VARCHAR(80), IN `in_relative` VARCHAR(80), IN `in_agreed` VARCHAR(10), IN `in_witness_by` VARCHAR(80), IN `in_patient_id` VARCHAR(15), IN `in_created_at` DATETIME, IN `in_created_by` VARCHAR(50), IN `facId` VARCHAR(50), IN `query_type` VARCHAR(20))   BEGIN
IF query_type = 'insert' then
INSERT INTO surgical_note_temp(template,facilityId) VALUES (in_template,facId);
ELSEIF query_type='select' THEN
SELECT template FROM surgical_note_temp WHERE facilityId=facId ORDER BY id DESC LIMIT 1;
ELSEIF query_type='insert_surgical_note' THEN
INSERT INTO `surgical_note`(`patient_name`, `relative`, `agreed`, `witness_by`, `patient_id`, `created_at`, `created_by`,facilityId) VALUES (in_patient_name,in_relative,in_agreed,in_witness_by,in_patient_id,in_created_at, in_created_by,facId);
ELSEIF query_type='select_surgical_note' THEN
SELECT * FROM surgical_note WHERE patient_id=in_patient_id AND facilityId=facId;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_dispensary` (IN `in_query_type` VARCHAR(50), IN `in_status` VARCHAR(50), IN `in_pr_id` VARCHAR(50))  NO SQL IF in_query_type = 'new schedule' THEN
	UPDATE dispensary SET schedule_status = 'scheduled' WHERE id = in_pr_id;
ELSE 
	UPDATE dispensary SET schedule_status = in_status WHERE id = in_pr_id;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_lab_test` (IN `in_query_type` VARCHAR(50), IN `in_booking_no` VARCHAR(50), IN `in_test` VARCHAR(50), IN `in_request_id` VARCHAR(50), IN `in_patient_id` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `in_status` VARCHAR(100), IN `in_user_id` VARCHAR(50), IN `in_doc_name` VARCHAR(150), IN `in_doc_title` VARCHAR(30), IN `in_dept` VARCHAR(50), IN `in_appearance` VARCHAR(500), IN `in_serology` VARCHAR(500), IN `in_culture_yielded` VARCHAR(500), IN `in_result` VARCHAR(500), IN `in_sensitivity` VARCHAR(500), IN `in_resistivity` VARCHAR(500), IN `in_intermediaryTo` VARCHAR(500), IN `in_o_value` VARCHAR(10), IN `in_h_value` VARCHAR(10), IN `in_unit` VARCHAR(20), IN `in_range_from` VARCHAR(20), IN `in_range_to` VARCHAR(20))  NO SQL IF in_query_type = 'remove' THEN
UPDATE lab_requisition SET status='removed', approval_status='removed' WHERE booking_no = in_booking_no AND test=in_test AND request_id=in_request_id;
    COMMIT;
ELSEIF in_query_type = 'by_booking' THEN
UPDATE lab_requisition SET status=in_status WHERE booking_no=in_booking_no AND facilityId=in_facId;
    
ELSEIF in_query_type = 'result' THEN
UPDATE lab_requisition SET appearance=in_appearance, serology=in_serology, culture_yielded=in_culture_yielded, result=in_result, status=in_status, sensitivity=in_sensitivity, resistivity=in_resistivity, intermediaryTo=in_intermediaryTo,unit=in_unit, 
        range_from=in_range_from, range_to=in_range_to, analyzed_by=in_user_id, analyzed_at=now(), o_value=in_o_value, h_value=in_h_value WHERE booking_no=in_booking_no AND test=in_test AND facilityId=in_facId;
        COMMIT;
    
ELSEIF in_query_type = 'comment' THEN
UPDATE lab_requisition SET status="result", token=lab_requisition.code,  result_by=in_user_id, result_at=now(),
        doctor_fullname=in_doc_name
        WHERE booking_no=in_booking_no AND department=in_dept
      AND facilityId=in_facId;
      COMMIT;
END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_number_generator` (IN `in_query_type` VARCHAR(50), IN `in_number` INT(50))  NO SQL BEGIN
UPDATE number_generator set code_no =in_number WHERE prefix=in_query_type;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_prescription` (IN `in_schedule_id` VARCHAR(50), IN `in_served_by` VARCHAR(50), IN `in_facId` VARCHAR(50), IN `in_reason` VARCHAR(500), IN `in_query_type` VARCHAR(20))  NO SQL IF in_query_type = 'served' THEN
	UPDATE drug_schedule SET status=in_query_type, served_by=in_served_by WHERE id=in_schedule_id AND facilityId=in_facId; 
ELSEIF in_query_type = 'not served' THEN
	UPDATE drug_schedule SET status=in_query_type, served_by=in_served_by, reason=in_reason WHERE id=in_schedule_id AND facilityId=in_facId; 
ELSEIF in_query_type = 'stop' THEN
	UPDATE drug_schedule SET status = in_query_type, stopped_by=in_served_by WHERE prescription_id = in_schedule_id AND status='scheduled' AND facilityId=in_facId;
    CALL update_dispensary(in_query_type,in_query_type,in_schedule_id);

END IF$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_user` (IN `in_accessTo` VARCHAR(255), IN `in_functionality` VARCHAR(2000), IN `in_id` INT, IN `in_facilityId` VARCHAR(50), IN `in_firstname` VARCHAR(50), IN `in_lastname` VARCHAR(50), IN `in_role` VARCHAR(50), IN `in_department` VARCHAR(50))   UPDATE users SET accessTo = in_accessTo,functionality = in_functionality, firstname=in_firstname, lastname=in_lastname, role=in_role,department=in_department WHERE id = in_id AND facilityId = in_facilityId$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `time_TEST` (`in_param` VARCHAR(50), `in_curr_hour` TIME, `in_date` DATE) RETURNS DATETIME  BEGIN

  DECLARE next_hour,next_hour2 time DEFAULT "00:00:00";
  DECLARE time_found datetime;

	IF in_param = 'STAT' THEN
    	SET time_found = now();
	ELSE
    	SELECT MIN(time)  INTO next_hour FROM  drug_frequency4  WHERE description=in_param AND time >= in_curr_hour;

	if next_hour is not null then
	set time_found=concat(in_date, ' ', next_hour);
	else
	SELECT MIN(time)  INTO next_hour2 FROM drug_frequency4  WHERE description=in_param;
	set time_found=concat(DATE_ADD(in_date,INTERVAL 1 day) ,' ', next_hour2);
	end if;
    END IF;
    
  RETURN time_found;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `account`
--

CREATE TABLE `account` (
  `head` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `balance` int(11) DEFAULT NULL,
  `subhead` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `account`
--

INSERT INTO `account` (`head`, `balance`, `subhead`, `description`, `price`, `facilityId`) VALUES
('10000', 0, '', 'PSC Specialist Hospital Limited', 0, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('30022', 0, '30000', 'Transport/Ambulance Service', 0, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('30023', 0, '30000', 'Insurance', 0, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `account2`
--

CREATE TABLE `account2` (
  `head` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `balance` int(11) DEFAULT NULL,
  `subhead` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `account2`
--

INSERT INTO `account2` (`head`, `balance`, `subhead`, `description`, `facilityId`) VALUES
('10000', 0, '', 'Asymco Pharmac', '6c6af0c0-35ea-40d8-a928-b13a9766113a'),
('60001', 0, '60000', 'Returned Drugs', '6c6af0c0-35ea-40d8-a928-b13a9766113a');

-- --------------------------------------------------------

--
-- Table structure for table `account4`
--

CREATE TABLE `account4` (
  `head` varchar(100) NOT NULL,
  `balance` int(11) DEFAULT NULL,
  `subhead` varchar(50) DEFAULT NULL,
  `description` varchar(500) DEFAULT NULL,
  `facilityId` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `accountb4`
--

CREATE TABLE `accountb4` (
  `head` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `balance` int(11) DEFAULT NULL,
  `subhead` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `price` varchar(11) DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `accountb4`
--

INSERT INTO `accountb4` (`head`, `balance`, `subhead`, `description`, `price`, `facilityId`) VALUES
('10000', 0, '', 'PSC Specialist Hospital Limited', '0', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('20000', 0, '10000', 'Revenue', '0', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('MAWSH.296', 0, '20000', 'Admission: Case Folder N500.00', '500', '052100000000'),
('MAWSH.297', 0, '20000', 'Admission: Medical Certificate', '100000', '052100000000');

-- --------------------------------------------------------

--
-- Table structure for table `account_asym_old`
--

CREATE TABLE `account_asym_old` (
  `head` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `balance` int(11) DEFAULT NULL,
  `subhead` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `account_asym_old`
--

INSERT INTO `account_asym_old` (`head`, `balance`, `subhead`, `description`, `facilityId`) VALUES
('10000', 0, '', 'Asymco Pharmac', '6c6af0c0-35ea-40d8-a928-b13a9766113a'),
('40001', 0, '40000', 'Drug Purchase', '6c6af0c0-35ea-40d8-a928-b13a9766113a');

-- --------------------------------------------------------

--
-- Table structure for table `account_entries`
--

CREATE TABLE `account_entries` (
  `id` int(11) NOT NULL,
  `acct` int(11) DEFAULT NULL,
  `dr` int(11) DEFAULT NULL,
  `cr` int(11) DEFAULT NULL,
  `description` varchar(100) NOT NULL,
  `reference_no` varchar(50) NOT NULL,
  `facilityId` varchar(50) NOT NULL,
  `createdAt` datetime DEFAULT current_timestamp(),
  `client_id` varchar(50) NOT NULL,
  `txn_status` varchar(50) NOT NULL,
  `quantity` int(11) NOT NULL,
  `mode_of_payment` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `account_entries`
--

INSERT INTO `account_entries` (`id`, `acct`, `dr`, `cr`, `description`, `reference_no`, `facilityId`, `createdAt`, `client_id`, `txn_status`, `quantity`, `mode_of_payment`) VALUES
(1, 1, 0, 0, 'Deposit from account 1', '240810145220', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-08-10 02:52:20', '1', 'completed', 0, NULL),
(2, 2, 0, 0, 'Deposit from account 2', '24081284659', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-08-12 08:46:59', '2', 'completed', 0, NULL),
(541, 1, 1000000, 0, 'Deposit from account 1', '0901262601091733452866', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 00:00:00', '1', 'completed', 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `account_entries_bkp`
--

CREATE TABLE `account_entries_bkp` (
  `id` int(11) NOT NULL DEFAULT 0,
  `acct` int(11) DEFAULT NULL,
  `dr` int(11) DEFAULT NULL,
  `cr` int(11) DEFAULT NULL,
  `description` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `reference_no` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `facilityId` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `createdAt` datetime DEFAULT current_timestamp(),
  `client_id` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `txn_status` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `quantity` int(11) NOT NULL,
  `mode_of_payment` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `account_head`
-- (See below for the actual view)
--
CREATE TABLE `account_head` (
`head` varchar(100)
,`subhead` varchar(50)
,`description` varchar(500)
,`des` varchar(500)
);

-- --------------------------------------------------------

--
-- Table structure for table `account_opt`
--

CREATE TABLE `account_opt` (
  `head` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `balance` int(11) DEFAULT NULL,
  `subhead` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `account_opt`
--

INSERT INTO `account_opt` (`head`, `balance`, `subhead`, `description`, `facilityId`) VALUES
('500021', 0, '50002', 'Payables', '966a89f6-05d8-4564-b319-2f8863821e75');

-- --------------------------------------------------------

--
-- Table structure for table `account_prime`
--

CREATE TABLE `account_prime` (
  `head` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `balance` int(11) DEFAULT NULL,
  `subhead` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `account_prime`
--

INSERT INTO `account_prime` (`head`, `balance`, `subhead`, `description`, `price`, `facilityId`) VALUES
('10000', 0, '', 'PSC Specialist Hospital Limited', 0, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('20000', 0, '10000', 'Revenue', 0, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('30000', 0, '10000', 'Expenses', 0, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('40000', 0, '10000', 'Asset', 0, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('50000', 0, '10000', 'Equity & Liability', 0, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('30023', 0, '30000', 'Insurance', 0, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `account_type`
--

CREATE TABLE `account_type` (
  `code` int(11) NOT NULL,
  `Category` varchar(40) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `account_type`
--

INSERT INTO `account_type` (`code`, `Category`) VALUES
(1, 'Expenditure'),
(2, 'Revenue'),
(3, 'Assets'),
(4, 'Liability');

-- --------------------------------------------------------

--
-- Table structure for table `account_ubec`
--

CREATE TABLE `account_ubec` (
  `head` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `balance` int(11) DEFAULT NULL,
  `subhead` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `account_ubec`
--

INSERT INTO `account_ubec` (`head`, `balance`, `subhead`, `description`, `price`, `facilityId`) VALUES
('10000', 0, '', 'UBEC', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `appconfig`
--

CREATE TABLE `appconfig` (
  `appName` varchar(30) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `appointment`
--

CREATE TABLE `appointment` (
  `id` int(11) NOT NULL,
  `user_id` varchar(20) DEFAULT NULL,
  `patientId` varchar(20) DEFAULT NULL,
  `patient_name` varchar(70) DEFAULT NULL,
  `appointmentType` varchar(40) DEFAULT NULL,
  `location` varchar(80) DEFAULT NULL,
  `notes` varchar(100) DEFAULT NULL,
  `start_at` datetime NOT NULL DEFAULT current_timestamp(),
  `end_at` datetime NOT NULL DEFAULT current_timestamp(),
  `facilityId` varchar(60) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `appointment`
--

INSERT INTO `appointment` (`id`, `user_id`, `patientId`, `patient_name`, `appointmentType`, `location`, `notes`, `start_at`, `end_at`, `facilityId`) VALUES
(8, '818', '7392-1', 'Ming Yang Ming', 'Follow up', '', '', '2022-12-19 07:30:00', '2022-12-19 07:30:00', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(9, '11', '6263-1', 'Yahaya Hotoro Habib', 'Follow up', '19 lamido crescent', 'follow-up', '2022-12-28 12:00:00', '2022-12-28 12:00:00', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(11, '850', '7452-1', 'Okoli Caroline', 'Follow up', '', '', '2023-07-17 02:00:00', '2023-07-17 02:00:00', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(12, '850', '10256-2', 'Zubair Hamida', 'Follow up', '', 'To see with CXR, FBC+Diff and ESR results', '2024-03-12 03:30:24', '2024-03-12 03:30:24', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(17, '5', '8-1', 'Murtala Dodo', 'Emergency', 'Top wing', 'lhuhuih', '2025-02-18 02:49:39', '2025-02-18 02:49:39', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(18, '5', '1-1', 'John Doe', '', 'Top wing', 'oiy7h', '2025-02-18 02:50:09', '2025-02-18 02:50:09', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(19, '5', '3-1', 'Nazif Musa', 'Routine', 'Top wing', 'llmkm', '2025-02-21 02:50:24', '2025-02-21 02:50:24', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(20, '5', '14-1', 'Salisu Umar', 'Checkup', 'PSC Prime', 'kjbbb jn', '2025-04-27 07:10:20', '2025-04-27 07:10:20', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(21, '5', '20-1', 'Zubairu Kalthum', 'Checkup', 'PSC Prime', 'kjhgvbjbvbnmnbv', '2025-04-28 10:04:43', '2025-04-28 10:04:43', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(22, '5', '35-1', 'Mustapha Aminu', 'Checkup', 'jaba', 'massage', '2025-10-30 08:56:23', '2025-10-30 08:56:23', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `appointments`
--

CREATE TABLE `appointments` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `phone` varchar(255) NOT NULL,
  `doctorId` int(11) DEFAULT NULL,
  `doctorName` varchar(255) DEFAULT NULL,
  `serviceId` int(11) DEFAULT NULL,
  `serviceName` varchar(255) DEFAULT NULL,
  `department` varchar(255) DEFAULT NULL,
  `date` date NOT NULL,
  `time` time NOT NULL,
  `source` varchar(255) DEFAULT 'chatbot',
  `status` varchar(255) DEFAULT 'pending',
  `facilityId` varchar(255) DEFAULT NULL,
  `referenceNumber` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_schedule`
--

CREATE TABLE `asset_schedule` (
  `code` int(11) NOT NULL,
  `description` varchar(100) NOT NULL,
  `cost` int(11) NOT NULL,
  `rate` int(11) NOT NULL,
  `daily_rate` int(11) NOT NULL,
  `purchase_date` date NOT NULL,
  `end_date` date NOT NULL,
  `deduction_date` date DEFAULT NULL,
  `percentage_rate` int(11) NOT NULL,
  `nbv_yearly` int(11) NOT NULL,
  `depreciation` varchar(50) NOT NULL,
  `amortization` varchar(50) NOT NULL,
  `years` int(11) NOT NULL,
  `nbv_monthly` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `facilityId` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `asset_schedule`
--

INSERT INTO `asset_schedule` (`code`, `description`, `cost`, `rate`, `daily_rate`, `purchase_date`, `end_date`, `deduction_date`, `percentage_rate`, `nbv_yearly`, `depreciation`, `amortization`, `years`, `nbv_monthly`, `created_at`, `created_by`, `facilityId`) VALUES
(30004, 'Office Complex', 3000000, 750000, 750000, '2020-10-08', '2024-10-08', NULL, 25, 3000000, '5', '', 5, 250000, '2020-10-08 14:51:35', 'admin', '966a89f6-05d8-4564-b319-2f8863821e75'),
(30005, 'MRI Machine', 50000000, 10000000, 10000000, '2020-10-08', '2025-10-08', NULL, 20, 50000000, '6', '', 6, 4166667, '2020-10-08 14:59:53', 'admin', '966a89f6-05d8-4564-b319-2f8863821e75'),
(30006, 'Toyota HILUX Emergency Vehicle', 12000000, 2400000, 2400000, '2020-10-08', '2025-10-08', NULL, 20, 12000000, '6', '', 6, 1000000, '2020-10-08 20:46:46', 'admin', '966a89f6-05d8-4564-b319-2f8863821e75'),
(400016, 'Toyota HILUX Emergency Vehicle', 400000, 80000, 80000, '2020-10-09', '2025-10-09', NULL, 20, 400000, '6', '', 6, 33333, '2020-10-09 14:24:20', 'admin', '966a89f6-05d8-4564-b319-2f8863821e75'),
(400014, 'Land', 1000000, 200000, 200000, '2020-10-10', '2025-10-10', NULL, 20, 1000000, '6', '', 6, 83333, '2020-10-10 18:08:48', 'admin', '966a89f6-05d8-4564-b319-2f8863821e75'),
(400014, 'Land', 1000000, 200000, 200000, '2020-10-11', '2025-10-11', NULL, 20, 1000000, '6', '', 6, 83333, '2020-10-11 10:17:05', 'admin', '966a89f6-05d8-4564-b319-2f8863821e75'),
(400014, 'Land', 6000000, 1200000, 1200000, '2020-10-11', '2025-10-11', NULL, 20, 6000000, '6', '', 6, 500000, '2020-10-11 12:01:43', 'admin', '966a89f6-05d8-4564-b319-2f8863821e75'),
(400012, 'Laptop', 120000, 30000, 30000, '2020-11-29', '2024-11-29', NULL, 25, 120000, '5', '', 5, 10000, '2020-11-29 15:04:44', 'bits', '121bb692-9a44-472f-b396-b68ebf798b30');

-- --------------------------------------------------------

--
-- Table structure for table `assignpatient`
--

CREATE TABLE `assignpatient` (
  `diagDate` date NOT NULL,
  `patientNo` varchar(50) NOT NULL,
  `seenBy` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `attendance`
--

CREATE TABLE `attendance` (
  `id` int(11) NOT NULL,
  `staffId` varchar(255) NOT NULL,
  `checkInTime` datetime DEFAULT NULL,
  `checkOutTime` datetime DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'checked-in',
  `location` varchar(255) DEFAULT NULL,
  `date` varchar(255) NOT NULL,
  `hederaTransactionId` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `audit_trail`
--

CREATE TABLE `audit_trail` (
  `facilityId` varchar(50) NOT NULL,
  `id` int(11) NOT NULL DEFAULT 0,
  `drug_name` varchar(100) NOT NULL,
  `supplier_name` varchar(100) DEFAULT NULL,
  `new_supplier_name` varchar(50) NOT NULL,
  `old_dispensary_balance` int(11) NOT NULL,
  `new_dispensary_balance` int(11) NOT NULL,
  `old_markup` int(11) NOT NULL,
  `new_markup` int(11) NOT NULL,
  `updated_by` varchar(50) NOT NULL,
  `deleted_by` varchar(50) NOT NULL,
  `source_table` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `audit_trail`
--

INSERT INTO `audit_trail` (`facilityId`, `id`, `drug_name`, `supplier_name`, `new_supplier_name`, `old_dispensary_balance`, `new_dispensary_balance`, `old_markup`, `new_markup`, `updated_by`, `deleted_by`, `source_table`, `created_at`) VALUES
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 0, 'amatem', NULL, '', 200, 196, 100, 100, 'abdurrahman', '', 'drugpurchaserecords', '2021-09-19 04:33:53'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 0, 'oxymet nasal drop', NULL, '', 6, 5, 0, 0, 'Abdulrauf', '', 'drugpurchaserecords', '2021-11-06 23:33:20'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 0, 'Tabs Dalcin C', NULL, '', 20, 11, 500, 500, 'abdurrahman', '', 'drugpurchaserecords', '2022-03-27 12:44:18');

-- --------------------------------------------------------

--
-- Table structure for table `barcode`
--

CREATE TABLE `barcode` (
  `id` int(11) NOT NULL,
  `lab_code` int(11) NOT NULL,
  `initials` int(11) NOT NULL,
  `year_code` int(11) NOT NULL,
  `barcode` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `barcode`
--

INSERT INTO `barcode` (`id`, `lab_code`, `initials`, `year_code`, `barcode`) VALUES
(1, 2000, 2, 21, 199944),
(2, 3000, 3, 21, 54990),
(3, 4000, 4, 21, 13139),
(4, 5000, 5, 21, 1);

-- --------------------------------------------------------

--
-- Table structure for table `bedlist`
--

CREATE TABLE `bedlist` (
  `id` int(11) NOT NULL,
  `sort_index` int(11) NOT NULL DEFAULT 0,
  `class_type` varchar(50) NOT NULL,
  `account` varchar(10) DEFAULT NULL,
  `price` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `no_of_beds` int(11) NOT NULL,
  `status` varchar(50) DEFAULT 'enable',
  `facilityId` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `bedlist`
--

INSERT INTO `bedlist` (`id`, `sort_index`, `class_type`, `account`, `price`, `name`, `no_of_beds`, `status`, `facilityId`) VALUES
(60, 0, 'Green House', NULL, 70000, 'Ward 2', 1, 'enable', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(59, 0, 'SUBMARINE', NULL, 89000, 'Classic', 3, 'enable', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(55, 0, 'Blue House', NULL, 120000, 'Blue House', 2, 'enable', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(56, 0, 'Green House', NULL, 250000, ' Ward 1', 1, 'enable', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(57, 0, '', NULL, 200000, ' Ward 3', 1, 'disabled', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(58, 0, 'ICU', NULL, 300000, 'ICU', 1, 'enable', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(54, 0, 'Yellow House', NULL, 120000, 'Yellow House', 2, 'disabled', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Stand-in structure for view `bedlist_view`
-- (See below for the actual view)
--
CREATE TABLE `bedlist_view` (
`id` int(11)
,`sort_index` int(11)
,`class_type` varchar(50)
,`price` int(11)
,`name` varchar(100)
,`status` varchar(50)
,`no_of_beds` int(11)
,`occupied` bigint(21)
,`facilityId` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `beds`
--

CREATE TABLE `beds` (
  `id` int(11) NOT NULL,
  `headtitle` varchar(100) DEFAULT NULL,
  `headcode` int(11) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bed_allocation`
--

CREATE TABLE `bed_allocation` (
  `id` int(11) NOT NULL,
  `bed_id` int(11) NOT NULL,
  `patient_id` varchar(50) NOT NULL,
  `allocation_status` varchar(20) DEFAULT NULL,
  `allocated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `ended` timestamp NULL DEFAULT NULL,
  `allocated_by` varchar(50) NOT NULL,
  `ended_by` varchar(50) DEFAULT NULL,
  `facilityId` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `bed_allocation`
--

INSERT INTO `bed_allocation` (`id`, `bed_id`, `patient_id`, `allocation_status`, `allocated`, `ended`, `allocated_by`, `ended_by`, `facilityId`) VALUES
(23, 9, '6-1', 'discharged', '2025-02-28 12:56:38', '2025-02-28 12:56:38', 'abdurrahman', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(22, 12, '3-1', 'discharged', '2025-02-28 11:02:44', '2025-02-28 11:02:44', 'abdurrahman', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(21, 10, '5-1', 'discharged', '2025-02-28 12:57:07', '2025-02-28 12:57:07', 'abdurrahman', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(8, 5, '2-1', 'discharged', '2025-02-28 09:45:39', '2025-02-28 09:45:39', 'abdurrahman', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(120, 59, '21-1', 'allocated', '2025-07-22 07:19:01', NULL, 'abdurrahman', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `bed_allocation_bkp`
--

CREATE TABLE `bed_allocation_bkp` (
  `id` int(11) NOT NULL DEFAULT 0,
  `bed_id` int(11) NOT NULL,
  `patient_id` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `allocation_status` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `allocated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `ended` timestamp NULL DEFAULT NULL,
  `allocated_by` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `ended_by` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `blogs`
--

CREATE TABLE `blogs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `author` varchar(100) NOT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `booking_no`
--

CREATE TABLE `booking_no` (
  `id` int(11) NOT NULL,
  `lab_code` int(11) NOT NULL,
  `year_code` int(11) NOT NULL,
  `booking` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `booking_no`
--

INSERT INTO `booking_no` (`id`, `lab_code`, `year_code`, `booking`) VALUES
(1, 0, 21, 266765);

-- --------------------------------------------------------

--
-- Table structure for table `branches`
--

CREATE TABLE `branches` (
  `id` int(11) NOT NULL,
  `branch_name` varchar(50) DEFAULT NULL,
  `state` varchar(50) DEFAULT NULL,
  `address` varchar(100) DEFAULT NULL,
  `created_time` timestamp NULL DEFAULT NULL,
  `facilityId` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bulk_tx`
--

CREATE TABLE `bulk_tx` (
  `facilityId` varchar(50) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `transaction_id` int(11) NOT NULL DEFAULT 0,
  `transaction_date` date DEFAULT NULL,
  `id` int(11) DEFAULT NULL,
  `description` varchar(225) DEFAULT NULL,
  `acct` varchar(100) DEFAULT NULL,
  `debit` int(50) DEFAULT NULL,
  `credit` int(50) DEFAULT NULL,
  `enteredBy` varchar(20) DEFAULT NULL,
  `receiptDateSN` varchar(18) NOT NULL DEFAULT '0',
  `receiptNo` int(7) DEFAULT 0,
  `modeOfPayment` varchar(15) DEFAULT NULL,
  `bank_name` varchar(50) DEFAULT NULL,
  `status` varchar(30) DEFAULT 'pending',
  `approvedBy` varchar(20) DEFAULT NULL,
  `paymentStatus` varchar(11) NOT NULL DEFAULT '',
  `client_acct` varchar(200) DEFAULT NULL,
  `patient_id` varchar(50) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `bulk_tx`
--

INSERT INTO `bulk_tx` (`facilityId`, `createdAt`, `transaction_id`, `transaction_date`, `id`, `description`, `acct`, `debit`, `credit`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `approvedBy`, `paymentStatus`, `client_acct`, `patient_id`) VALUES
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-12-08 06:09:18', 1, '2020-12-01', NULL, 'Medications', '20030', 0, 1100, 'abdurrahman', '08122011', 1, 'cash', '', 'pending', NULL, '', '4708', '4667-1'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-02-18 05:47:49', 5382, '2021-02-01', NULL, 'Specialist F/up', '400022', 6000, 0, 'Manager', '180221165381', 16, 'POS', '', 'pending', NULL, '', '4708', '3975-1');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`) VALUES
(5, 'Creative'),
(4, 'Design'),
(6, 'Education'),
(1, 'General'),
(2, 'Lifestyle'),
(3, 'Travel');

-- --------------------------------------------------------

--
-- Table structure for table `charges_fees`
--

CREATE TABLE `charges_fees` (
  `id` int(11) NOT NULL,
  `patient_id` varchar(20) NOT NULL,
  `user_id` varchar(20) NOT NULL,
  `dr` float NOT NULL,
  `cr` float NOT NULL,
  `description` varchar(100) NOT NULL,
  `status` varchar(30) DEFAULT NULL,
  `patientType` varchar(30) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `facilityId` varchar(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `charges_fees`
--

INSERT INTO `charges_fees` (`id`, `patient_id`, `user_id`, `dr`, `cr`, `description`, `status`, `patientType`, `created_at`, `facilityId`) VALUES
(1, '1-1', 'abdurrahman', 300, 0, 'Consultation', 'New Consultation', 'in-patients', '2024-08-10 14:04:39', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(2, '2-1', 'abdurrahman', 300, 0, 'Consultation', 'New Consultation', 'null', '2024-08-20 10:23:46', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(581, '2-1', 'abdurrahman', 300, 0, 'Consultation', 'New Consultation', 'null', '2026-01-09 16:30:39', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(582, '4-1', 'abdurrahman', 300, 0, 'Consultation', 'New Consultation', 'out-patients', '2026-01-09 17:32:37', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `charges_fees_temp`
--

CREATE TABLE `charges_fees_temp` (
  `id` int(11) NOT NULL,
  `revenueSource` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL,
  `accountHead` int(11) NOT NULL,
  `time_laps` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `charges_fees_temp`
--

INSERT INTO `charges_fees_temp` (`id`, `revenueSource`, `amount`, `accountHead`, `time_laps`) VALUES
(1, 'Pharmarcy', 100, 200, 1),
(2, 'Laboratory', 100, 300, 1),
(3, 'Consultation', 300, 400, 30);

-- --------------------------------------------------------

--
-- Table structure for table `chartofaccount`
--

CREATE TABLE `chartofaccount` (
  `code` varchar(3) NOT NULL,
  `head` varchar(100) DEFAULT NULL,
  `subHead` varchar(100) DEFAULT NULL,
  `description` varchar(20) NOT NULL,
  `balance` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `chartofaccount`
--

INSERT INTO `chartofaccount` (`code`, `head`, `subHead`, `description`, `balance`) VALUES
('CLN', NULL, NULL, 'clinic', 62900),
('LAB', NULL, NULL, 'lab', 0);

-- --------------------------------------------------------

--
-- Table structure for table `chatbot_sessions`
--

CREATE TABLE `chatbot_sessions` (
  `id` int(11) NOT NULL,
  `sessionId` varchar(255) NOT NULL,
  `currentStep` varchar(255) DEFAULT 'greeting',
  `intent` varchar(255) DEFAULT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`data`)),
  `facilityId` varchar(255) DEFAULT NULL,
  `lastActivity` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `chatbot_sessions`
--

INSERT INTO `chatbot_sessions` (`id`, `sessionId`, `currentStep`, `intent`, `data`, `facilityId`, `lastActivity`, `createdAt`, `updatedAt`) VALUES
(1, 'session-1763378681550-76dxgw91p', 'greeting', NULL, '{}', 'prime-clinic-001', '2025-11-17 11:24:50', '2025-11-17 11:24:50', '2025-11-17 11:24:50'),
(2, 'session-1763379135419-qo6xx3mpr', 'greeting', NULL, '{}', 'prime-clinic-001', '2025-11-17 11:39:02', '2025-11-17 11:32:24', '2025-11-17 11:39:02'),
(3, 'session-1763379575821-4o3vlfmyx', 'select_doctor', 'book_appointment', '{}', 'prime-clinic-001', '2025-11-17 11:48:55', '2025-11-17 11:41:42', '2025-11-17 11:48:55'),
(4, 'session-1763384787546-cv0rulfrj', 'ask_patient_id', 'book_appointment', '{}', 'prime-clinic-001', '2025-11-17 13:08:01', '2025-11-17 13:06:51', '2025-11-17 13:08:01'),
(5, 'session-1763385230717-7c2e5d30j', 'ask_patient_id', 'book_appointment', '{}', 'prime-clinic-001', '2025-11-17 13:14:04', '2025-11-17 13:13:55', '2025-11-17 13:14:04'),
(6, 'session-1763385366809-d000dmvlr', 'ask_patient_id', 'book_appointment', '{}', 'prime-clinic-001', '2025-11-17 13:16:19', '2025-11-17 13:16:15', '2025-11-17 13:16:19'),
(7, 'session-1763385493304-jfz0edsjk', 'ask_doctor_or_department', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 13:19:23', '2025-11-17 13:18:19', '2025-11-17 13:19:23'),
(8, 'session-1763385913056-95chwcsv2', 'select_doctor', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 13:25:21', '2025-11-17 13:25:15', '2025-11-17 13:25:21'),
(9, 'session-1763386349962-3m9herk9m', 'select_doctor', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 13:34:16', '2025-11-17 13:32:36', '2025-11-17 13:34:16'),
(10, 'session-1763386739099-hkwjfc3n7', 'ask_patient_id', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 13:39:07', '2025-11-17 13:39:02', '2025-11-17 13:39:07'),
(11, 'session-1763386993360-c81v30d5j', 'select_doctor', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 13:43:31', '2025-11-17 13:43:19', '2025-11-17 13:43:31'),
(12, 'session-1763387662382-dj9kfcrdc', 'select_doctor', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 13:54:35', '2025-11-17 13:54:28', '2025-11-17 13:54:35'),
(13, 'session-1763387916115-qdgtmvieh', 'ask_date', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 14:01:43', '2025-11-17 13:58:41', '2025-11-17 14:01:43'),
(14, 'session-1763388332697-7jgvmvswn', 'greeting', NULL, '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 14:05:39', '2025-11-17 14:05:39', '2025-11-17 14:05:39'),
(15, 'session-1763388429583-8hhyis2c9', 'select_doctor', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 14:07:23', '2025-11-17 14:07:15', '2025-11-17 14:07:23'),
(16, 'session-1763388976293-84c6lx008', 'ask_date', 'book_appointment', '{\"doctorId\":5,\"doctorName\":\"Abdurrahman Nasir\",\"department\":\"General\"}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 14:19:19', '2025-11-17 14:16:26', '2025-11-17 14:19:19'),
(17, 'session-1763389352772-u62mve0ev', 'select_doctor', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 14:22:46', '2025-11-17 14:22:35', '2025-11-17 14:22:46'),
(18, 'session-1763389746827-7cn1am8af', 'select_doctor', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 14:29:35', '2025-11-17 14:29:27', '2025-11-17 14:29:35'),
(19, 'session-1763390311404-8unary9m1', 'select_doctor', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 14:38:44', '2025-11-17 14:38:34', '2025-11-17 14:38:44'),
(20, 'session-1763390883897-4ysnh5d3v', 'select_doctor', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 14:48:13', '2025-11-17 14:48:07', '2025-11-17 14:48:13'),
(21, 'session-1763391238129-sblq6mr2i', 'select_doctor', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 14:54:19', '2025-11-17 14:54:01', '2025-11-17 14:54:19'),
(22, 'session-1763391402120-37xhem90w', 'ask_date', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 14:59:39', '2025-11-17 14:56:44', '2025-11-17 14:59:39'),
(23, 'session-1763392024252-72duejz2n', 'ask_date', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 15:10:21', '2025-11-17 15:07:07', '2025-11-17 15:10:21'),
(24, 'session-1763392471149-avqmy0wp6', 'confirm', 'book_appointment', '{\"time\":\"11:00\"}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 15:18:08', '2025-11-17 15:15:36', '2025-11-17 15:18:08'),
(25, 'session-1763394542806-n0v6rq134', 'confirm', 'book_appointment', '{\"time\":\"10:00\"}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 15:55:23', '2025-11-17 15:54:07', '2025-11-17 15:55:23'),
(26, 'session-1763396224637-k5kl0yolh', 'confirm', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-17 16:17:43', '2025-11-17 16:17:28', '2025-11-17 16:17:43'),
(27, 'test-session-123', 'ask_phone', 'book_appointment', '{}', 'facility-001', '2025-11-18 09:40:40', '2025-11-18 09:31:47', '2025-11-18 09:40:40'),
(28, 'session-1763460587317-50u9f76ql', 'confirm', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 10:12:51', '2025-11-18 10:09:53', '2025-11-18 10:12:51'),
(29, 'session-1763461407164-nkio22wwi', 'confirm', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 10:24:59', '2025-11-18 10:23:31', '2025-11-18 10:24:59'),
(30, 'session-1763461655617-fd5ubeuhm', 'ask_date', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 10:27:46', '2025-11-18 10:27:39', '2025-11-18 10:27:46'),
(31, 'session-1763461910759-f6ewtchef', 'ask_date', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 10:32:03', '2025-11-18 10:31:55', '2025-11-18 10:32:03'),
(32, 'session-1763462265091-n2al404xb', 'ask_date', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 10:39:13', '2025-11-18 10:37:53', '2025-11-18 10:39:13'),
(33, 'session-1763462623125-p0bvqfgfw', 'ask_date', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 10:43:57', '2025-11-18 10:43:47', '2025-11-18 10:43:57'),
(34, 'session-1763462893838-42g8e4u5p', 'ask_date', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 10:48:33', '2025-11-18 10:48:19', '2025-11-18 10:48:33'),
(35, 'session-1763463245917-ay5jk54y6', 'ask_date', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 10:54:27', '2025-11-18 10:54:13', '2025-11-18 10:54:27'),
(36, 'session-1763468827505-43sabnwa6', 'ask_date', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 12:27:56', '2025-11-18 12:27:10', '2025-11-18 12:27:56'),
(37, 'session-1763468887151-9t0ff9qfe', 'greeting', NULL, '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 12:28:28', '2025-11-18 12:28:16', '2025-11-18 12:28:29'),
(38, 'session-1763475131419-zuixes1qn', 'ask_patient_id', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 14:12:25', '2025-11-18 14:12:23', '2025-11-18 14:12:25'),
(39, 'session-1763475155639-fuvls66vu', 'greeting', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 14:19:50', '2025-11-18 14:12:41', '2025-11-18 14:19:50'),
(40, 'session-1763476435640-yvrkwpjko', 'greeting', 'book_appointment', '{}', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-18 14:43:33', '2025-11-18 14:35:52', '2025-11-18 14:43:33');

-- --------------------------------------------------------

--
-- Table structure for table `comment`
--

CREATE TABLE `comment` (
  `facilityId` varchar(50) DEFAULT NULL,
  `id` int(100) NOT NULL,
  `booking_no` varchar(100) DEFAULT NULL,
  `user_id` varchar(100) DEFAULT NULL,
  `comment` varchar(3000) DEFAULT NULL,
  `useTemplate` varchar(50) DEFAULT NULL,
  `comment_type` varchar(50) DEFAULT NULL,
  `lab_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `comments`
--

CREATE TABLE `comments` (
  `id` int(11) NOT NULL,
  `post_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `content` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `parent_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `comments`
--

INSERT INTO `comments` (`id`, `post_id`, `user_id`, `name`, `email`, `content`, `created_at`, `parent_id`) VALUES
(1, 2, NULL, 'Sadiq Haruna', 'harunakadiri702@gmail.com', 'i was there live', '2024-04-09 10:23:42', NULL),
(2, 2, NULL, 'faith', 'faith@gmail.com', 'Well presented', '2025-04-09 10:29:32', NULL),
(3, 2, NULL, 'musa', 'dangana@gmail.com', 'Wow send me your account number for that', '2025-04-09 11:18:50', 1),
(4, 4, NULL, 'frank donga', 'test@gmail.com', 'something', '2025-04-09 11:32:06', NULL),
(5, 4, NULL, 'haruna kadiri', 'harunakadiri702@gmail.com', 'xzxcxc', '2025-04-09 11:32:27', 4);

-- --------------------------------------------------------

--
-- Table structure for table `consultations`
--

CREATE TABLE `consultations` (
  `id` varchar(50) NOT NULL,
  `patient_id` varchar(50) NOT NULL,
  `patient_name` varchar(60) DEFAULT NULL,
  `userId` varchar(50) NOT NULL,
  `seen_by` varchar(60) DEFAULT NULL,
  `consultation_notes` varchar(4000) NOT NULL,
  `treatmentPlan` varchar(4000) NOT NULL,
  `decision` varchar(50) NOT NULL,
  `dressing_request` varchar(500) NOT NULL,
  `nursing_request` varchar(500) NOT NULL,
  `nursing_request_status` varchar(20) NOT NULL DEFAULT 'pending',
  `facilityId` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `treatment_plan_status` varchar(20) NOT NULL DEFAULT 'pending',
  `treatment_by` varchar(20) DEFAULT NULL,
  `icd_code` varchar(255) NOT NULL,
  `icd_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `consultations`
--

INSERT INTO `consultations` (`id`, `patient_id`, `patient_name`, `userId`, `seen_by`, `consultation_notes`, `treatmentPlan`, `decision`, `dressing_request`, `nursing_request`, `nursing_request_status`, `facilityId`, `created_at`, `treatment_plan_status`, `treatment_by`, `icd_code`, `icd_name`) VALUES
('081bcc94-4d49-4be8-8f98-506a04d84593', '35-1', 'Aminu Mustapha', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-08-05 15:11:29', 'pending', NULL, 'O048', '(Induced) termination of pregnancy w oth and unsp comp'),
('1388330d-cecf-4ad3-9f6f-2556a109f2db', '35-1', 'Aminu Mustapha', 'abdurrahman', 'Abdurrahman Nasir', 'some clerking', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-07-23 14:25:53', 'pending', NULL, 'G912', '(Idiopathic) normal pressure hydrocephalus'),
('1cf84f0d-073f-4f89-925a-3d41d1020380', '35-1', 'Aminu Mustapha', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-09-04 12:31:18', 'pending', NULL, 'O0489', '(Induced) termination of pregnancy with other complications'),
('2c0fcaa6-1aa6-492e-b9a7-c0158e70e6a1', '23-1', 'Mustapha Bakura', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 11:24:06', 'pending', NULL, 'Z3A11', '11 weeks gestation of pregnancy'),
('30671ab7-ce91-4912-9776-69b119ddf667', '25-1', 'Solar Solar', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-08-18 09:14:32', 'pending', NULL, 'Z3A11', '11 weeks gestation of pregnancy'),
('32d31c26-a863-49df-b898-75eb15924e1e', '30-1', 'Mily Moily', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-08-18 09:24:50', 'pending', NULL, 'O0480', '(Induced) termination of pregnancy with unsp complications'),
('36f68e02-ec9e-4eef-adb6-47c86391214c', '31-1', 'Today Today', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 11:29:27', 'pending', NULL, 'Z3A12', '12 weeks gestation of pregnancy'),
('388a1e52-6008-4762-81c4-22387481e04c', '34-1', 'Sadiq Fgfff', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 10:07:45', 'pending', NULL, 'O0480', '(Induced) termination of pregnancy with unsp complications'),
('392548ad-6e07-4f5b-b360-0c95e8c4234f', '28-1', 'Boss Bossskk', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-09-04 12:31:37', 'pending', NULL, 'O0480', '(Induced) termination of pregnancy with unsp complications'),
('4765056d-1cf2-4222-ba4b-57399efb1823', '37-1', 'Sadiq Bashir', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 09:09:14', 'pending', NULL, 'Z3A11', '11 weeks gestation of pregnancy'),
('4e99f970-0a1e-47c2-b309-8987e692763b', '4-1', 'Ibrahim Ishaq', 'abdurrahman', 'Abdurrahman Nasir', 'uihiuhuh', 'iojioj', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 17:32:37', 'pending', NULL, '', ''),
('54701055-c4d5-4a7f-8092-fc2b5d95d228', '35-1', 'Aminu Mustapha', 'abdurrahman', 'Abdurrahman Nasir', 'none', 'none', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-08-18 08:56:38', 'pending', NULL, 'Z3A10', '10 weeks gestation of pregnancy'),
('586a9658-82df-4ea7-a95b-1ee1dcf154fc', '2-1', 'Account Family', 'abdurrahman', 'Abdurrahman Nasir', 'Clerking', 'Treatment', 'out-patient', 'ksksks', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:18:46', 'pending', NULL, '', ''),
('62e4ed0d-8a89-48db-8142-ecc74ef74272', '21-1', 'Amina Amina', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-08-18 09:07:10', 'pending', NULL, 'O0480', '(Induced) termination of pregnancy with unsp complications'),
('712fe652-0955-49eb-af3a-2c39b4f1b84a', '2-1', 'Account Family', 'abdurrahman', 'Abdurrahman Nasir', 'Testing', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:30:39', 'pending', NULL, '', ''),
('7b24766f-8e1b-4339-8f13-a8ebdd87963b', '21-1', 'Amina Amina', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-08-11 12:08:27', 'pending', NULL, 'G912', '(Idiopathic) normal pressure hydrocephalus'),
('7fb85acd-e2c4-4dca-8a77-0ca36be2a10e', '33-1', 'David Solomn', 'abdurrahman', 'Abdurrahman Nasir', 'dweq', 'erferf', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 09:43:05', 'pending', NULL, 'O0489', '(Induced) termination of pregnancy with other complications'),
('842d8b25-ff5c-40de-9997-9ba5cf416346', '35-1', 'Aminu Mustapha', 'abdurrahman', 'Abdurrahman Nasir', 'final review', '', 'discharge', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 12:48:08', 'pending', NULL, 'O0489', '(Induced) termination of pregnancy with other complications'),
('8d7cb1a6-3b9a-4326-8cab-f1a52e52d9dd', '24-1', 'Kate Kate', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 11:25:32', 'pending', NULL, 'Z3A15', '15 weeks gestation of pregnancy'),
('8fdad614-580c-4afe-9d72-2618551f3dfd', '2-1', 'Account Family', 'abdurrahman', 'Abdurrahman Nasir', 'Testung clerking notes', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:01:43', 'pending', NULL, '', ''),
('b0caa3a3-21e9-42fe-9caa-5bf61615ab10', '34-1', 'Sadiq Fgfff', 'abdurrahman', 'Abdurrahman Nasir', 'jjj', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-08-10 15:12:31', 'pending', NULL, 'Z3A11', '11 weeks gestation of pregnancy'),
('b1f56ecc-ef21-432c-86a1-8db4860bc6e5', '33-1', 'David Solomn', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 09:45:16', 'pending', NULL, 'O048', '(Induced) termination of pregnancy w oth and unsp comp'),
('c3f18d61-52c6-4d7d-b42e-d12c34541f71', '35-1', 'Aminu Mustapha', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-12 12:28:20', 'pending', NULL, 'Z3A12', '12 weeks gestation of pregnancy'),
('cbdb8689-7d29-44e5-bb52-cd7d83ddcf91', '35-1', 'Aminu Mustapha', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-08-27 10:47:45', 'pending', NULL, 'G912', '(Idiopathic) normal pressure hydrocephalus'),
('cd21cfea-9cc0-4263-9424-187372f453f1', '35-1', 'Aminu Mustapha', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 10:25:58', 'pending', NULL, 'O048', '(Induced) termination of pregnancy w oth and unsp comp'),
('d29fc927-bcb7-4f26-911f-1ff4c4a6da55', '19-1', 'Haruna Donald', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 10:57:40', 'pending', NULL, 'Z3A11', '11 weeks gestation of pregnancy'),
('dd335572-a1b8-4466-a446-d48bd2d14e1e', '23-1', 'Mustapha Bakura', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 11:23:22', 'pending', NULL, 'Z3A10', '10 weeks gestation of pregnancy'),
('e0894a4d-b03c-4c87-8e1c-336c6444453e', '35-1', 'Aminu Mustapha', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-07-23 10:15:23', 'pending', NULL, 'O048', '(Induced) termination of pregnancy w oth and unsp comp'),
('e64b47ba-a421-4d38-aee5-f9ea735ef992', '33-1', 'David Solomn', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 09:36:13', 'pending', NULL, 'O0480', '(Induced) termination of pregnancy with unsp complications'),
('ef05c833-1361-47d3-935b-f1e13ddc55f8', '36-1', 'FESTUS OBAMA', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 09:11:46', 'pending', NULL, 'Z3A12', '12 weeks gestation of pregnancy'),
('f2d4c928-b10e-41c0-b36b-b7045df51d23', '21-1', 'Amina Amina', 'abdurrahman', 'Abdurrahman Nasir', 'ewr', 'wedf', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-07-23 12:47:43', 'pending', NULL, 'G912', '(Idiopathic) normal pressure hydrocephalus'),
('fea12900-1a63-45da-9c85-10e7969516b4', '30-1', 'Mily Moily', 'abdurrahman', 'Abdurrahman Nasir', '', '', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 11:11:09', 'pending', NULL, 'Z3A11', '11 weeks gestation of pregnancy');

-- --------------------------------------------------------

--
-- Table structure for table `consultations_bkp`
--

CREATE TABLE `consultations_bkp` (
  `id` varchar(50) NOT NULL,
  `patient_id` varchar(50) NOT NULL,
  `patient_name` varchar(60) DEFAULT NULL,
  `userId` varchar(50) NOT NULL,
  `seen_by` varchar(60) DEFAULT NULL,
  `consultation_notes` varchar(4000) NOT NULL,
  `treatmentPlan` varchar(4000) NOT NULL,
  `decision` varchar(50) NOT NULL,
  `dressing_request` varchar(500) NOT NULL,
  `nursing_request` varchar(500) NOT NULL,
  `nursing_request_status` varchar(20) NOT NULL DEFAULT 'pending',
  `facilityId` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `treatment_plan_status` varchar(20) NOT NULL DEFAULT 'pending',
  `treatment_by` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `consultations_bkp`
--

INSERT INTO `consultations_bkp` (`id`, `patient_id`, `patient_name`, `userId`, `seen_by`, `consultation_notes`, `treatmentPlan`, `decision`, `dressing_request`, `nursing_request`, `nursing_request_status`, `facilityId`, `created_at`, `treatment_plan_status`, `treatment_by`) VALUES
('000199fc-d60b-4695-b494-bfe2f6887475', '9045-2', 'Isa Adam', 'drmuby', 'Musa Mubarak', 'Pt seen\n\n3DPO\nHad T11/T12/L2/L3 PSF + Laminectomy 2° to T12/L1 wedge collapse with myelopathy\nNFC\no/e GCS, anicteric, not pale, not dehydrated, NPE\nBP=120/70 mmhg, Pr= 80mmhg\nSpo2- 93% on RA\nDrain in situ draining about 80 mls of mixed blood in 24hrs\nASS= Stable post op', 'Do post op X-ray\nCt ongoing Medication', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-16 12:14:28', 'pending', NULL),
('06400387-73ef-4094-b39b-389c2a53209c', '9045-2', 'Isa Adam', 'mk', 'DR MK Abubakar', 'seen\nwith difficulty walking for 2month\n20yrs history of trauma\nno fever\no/e                                                                                                                                                                   gibbus', 'x ray, mri,\npsa,uric acid, fbc', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-01-29 16:48:41', 'pending', NULL),
('13f6a6e9-3f7a-4897-9c09-b21af34e7358', '9045-2', 'Isa Adam', 'Dr abm', 'Abubakar Bala', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-18 12:29:00', 'pending', NULL),
('1b739f19-8f1c-4632-b774-776ba5ceb09e', '9045-2', 'Isa Adam', 'Dr abm', 'Abubakar Bala', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-17 13:28:59', 'pending', NULL),
('29ffa71e-0bf5-437a-a6cf-448d970ae8a8', '9045-2', 'Isa Adam', 'drmuby', 'Musa Mubarak', 'Pt seen\n2DPO\nHad T11/T12/L2/L3 PSF + Laminectomy 2° to T12/L1 wedge collapse with myelopathy\nc/o of pain has subsided\nNFC\n\no/e GCS, anicteric, not pale, not dehydrated, NPE\n\nBP=120/70 mmhg, Pr= 80mmhg\n\nSpo2- 93% on RA\nDrain insitu draining about 700mls of mixed blood in 48hrs\nASS= Stable post op', 'Empty drain\nct post op medication\ndo post op fbc x diff', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-15 10:31:24', 'pending', NULL),
('3d5e05a8-9725-4ff2-a874-50dcc3237144', '9045-2', 'Isa Adam', 'King', 'Dr James King', 'Ward Round.\n\nPatient seen. 6DPO\n\nA case of T12/L1 wedge collapse with myelopathy.\n\nHe had T11/T12/L2/L3 PSF + Laminectomy surgery 6 days ago.\n\nPatient still c/o Left LL weakness.\n\nStable and calm.\n\nNFC today.\n\no/e: GC stable, not pale, afebrile, acyanosed, anicteric, not dehydrated, nil pedal edema.\n\nOp-site --Clean and dry, draining 200mls of SHF\n\nPR=80b/m, 110/60mmHg\n\nSpO2--95% in room air \n\nAss: Stable.\n\n', 'To do  post-op  Thoroco- Lumbar XR...ap and lat.\nIntensive physiotherapy (Call Sadiq Physio)\nRemove drain.\nWound dressing.\nThoraco-lumbar corset application\nContinue other management.\nComplete IV medications and commence..\nTabs Levofloxacin 500mg every 12 Hourly for 5 days\nCaps Clindamycin 300mg TDS x\nTabs Pregabalin 75mg every 12 Hourly for 5 days\nTabs Neurovite i every Once Daily for 2 weeks\nTabs Eproxen 500mg every 12 Hourly for 10 days', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-19 10:40:41', 'pending', NULL),
('40d5bf43-e781-432a-92ee-3e4d8b46ecd3', '9045-2', 'Isa Adam', 'mk', 'DR MK Abubakar', 'SEEN\n3MONTH POST OP\nAMBULATING WELL', 'FLOTAC\nANOROL', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-05-16 17:06:45', 'pending', NULL),
('497f6a97-d223-40f2-9877-bff390b45c26', '9045-2', 'Isa Adam', 'King', 'Dr James King', 'Ward Round.\n\nPatient seen. 7DPO\n\nA case of T12/L1 wedge collapse with myelopathy.\n\nHe had T11/T12/L2/L3 PSF + Laminectomy surgery\nStable and calm.\n\nNFC today.\n\no/e: GC stable, not pale, afebrile, acyanosed, anicteric, not dehydrated, nil pedal edema.\n\nOp-site --Clean and dry, draining 200mls of SHF\n\nPR=80b/m, 120/70mmHg\n\nSpO2--95% in room air\n\nAss: Stable.\n', 'Continue physiotherapy \nWound dressing.\nThoraco-lumbar corset application\nContinue other management.', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-20 12:04:08', 'pending', NULL),
('4b3e52d4-c1d7-42f7-ae5e-802c567723d8', '9045-2', 'Isa Adam', 'King', 'Dr James King', 'Ward Round.\n\nPatient seen. 8DPO\n\nA case of T12/L1 wedge collapse with myelopathy.\n\nHe had T11/T12/L2/L3 PSF + Laminectomy surgery\n\nStable and calm.\n\nNFC today.\n\no/e: GC stable, not pale, afebrile, acyanosed, anicteric, not dehydrated, nil pedal edema.\n\nOp-site --Clean and dry, draining 200mls of SHF\n\nPR=80b/m, 130/70mmHg\n\nSpO2--96% in room air\n\nAss: Stable.\n', 'FOR DR MK REVIEW \nContinue physiotherapy\n\nWound dressing.\n\nThoraco-lumbar corset application\n\nContinue other management.', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-21 10:53:27', 'pending', NULL),
('4b7e75dc-cac3-4be2-8273-0e7a972e36a5', '9045-2', 'Isa Adam', 'Dr abm', 'Abubakar Bala', 'WARD ROUND\n\nPt seen\n\n5DPO\n\nHad T11/T12/L2/L3 PSF + Laminectomy 2° to T12/L1 wedge collapse with myelopathy\n\nC/O FEVER,JOINT PAIN,COUGH AND CATARRH\n\no/e GCS, anicteric, not pale, not dehydrated, NPE\n\nBP=120/70 mmhg, Pr= 80mmhg\n\nSpo2- 93% on RA\n\nWOUND DRESSING =SOAKED\n\nDrain in situ draining about 100 mls of mixed blood in 24hrs\n\nASS= Stable post op+ ?MALARIA +RTI', 'DO MPS \nSYR BROZELIN 10MLS TDS \nIM EMAL 150MG STAT\nIV PCM 300MG 8HRLY X 24HRS ', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-18 12:16:10', 'pending', NULL),
('528dbe0f-889d-4a4b-b106-322992b50829', '9045-2', 'Isa Adam', 'Dr mubarak', 'Dr mubarak Abba Usman ', '', '', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-13 21:01:52', 'pending', NULL),
('6464909b-faa4-486e-a83e-d78c22dd5e7f', '9045-2', 'Isa Adam', 'drmuby', 'Musa Mubarak', 'Pt seen\n\nA case of compressive myelopathy of t12/l1\n\nBeing prepared for surgery\n\nHas NFC today\n\no/e GCS, afebrile, anicteric, acyanosed, not dehydrated, NPE\n\nBp=110/80mmhg, Pr-76b/m\n\nSpo2-98% on RA\n\nASS- Same', 'for surgery today', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-13 11:55:28', 'pending', NULL),
('84fa0c41-d1c0-4ea1-9a67-fcecf673ad98', '9045-2', 'Isa Adam', 'drmuby', 'Musa Mubarak', 'Pt seen\nA case of compressive myelopathy of t12/l1\nBeing prepared for surgery\nHas NFC today\no/e GCS, afebrile, anicteric, acyanosed, not dehydrated, NPE\nBp=110/80mmhg, Pr-76b/m\nSpo2-98% on RA\nASS- Same', 'For surgery on tuesday as planned', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-12 10:51:19', 'pending', NULL),
('9dbef49b-c413-450b-a836-01a253be0589', '9045-2', 'Isa Adam', 'Dr abm', 'Abubakar Bala', 'WARD ROUND \nPt seen\n\n4DPO\n\nHad T11/T12/L2/L3 PSF + Laminectomy 2° to T12/L1 wedge collapse with myelopathy\n\nNFC TODAY\n\no/e GCS, anicteric, not pale, not dehydrated, NPE\n\nBP=120/70 mmhg, Pr= 80mmhg\n\nSpo2- 93% on RA\nWOUND DRESSING =SOAKED\nDrain in situ draining about 100 mls of mixed blood in 24hrs\n\nASS= Stable post op', 'CHANGE WOUND DRESSING \nCT PHYSIOTHERAPHY \nCT ONGOING MGT ', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-17 11:34:04', 'pending', NULL),
('b96a1573-989b-48d2-aa13-6e486a3ad628', '9045-2', 'Isa Adam', 'mk', 'DR MK Abubakar', 'seen\nwith post traumatic gibbus \nhad been progressive\nnow associated with difficulty w2alking\nmri wege collapse of t12\nsensation intact\npower lower limb\n4/5 grossly\nASS compressive myelopathy of t12/l1\n', 'ADMIT PRIVATE 2\nfor surgery on tuesday\nfbc, clotting profile,\nu and e, \nECHO ECG\nGROUP AND XMATCH 2PINT', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-11 13:55:42', 'pending', NULL),
('c7daf9cb-424d-4680-9198-11ba5e5f2038', '9045-2', 'Isa Adam', 'drmuby', 'Musa Mubarak', 'Pt seen\n1DPO\nHad T11/T12/L2/L3 PSF + Laminectomy 2° to T12/L1 wedge collapse with myelopathy\nc/o of pain at op site\nNFC\no/e in painful distress, anicteric, not pale, not dehydrated, NPE\nBP=120/70 mmhg, Pr= 80mmhg\nSpo2- 93% on RA\nASS= Stable post op\n', 'iv omeprazole 20mg 12hrly x 48hrs\nim diclofenac 75mg 12hrly x 48hrs', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-14 11:24:04', 'pending', NULL),
('d0e038c4-9a55-48a0-9fae-fe964b1dd5d6', '9045-2', 'Isa Adam', 'Salihi', 'Dr Salihi Abdulmalik', 'Seen\n19 days post op \nPatient has significant improvement, power in the lower limbs improved\nAbmulating with BAC\nASS: Improving', 'Tabs Pregabalin 75 mg bd\nTabs Eproxane PRN\nTabs Neurovite I od', 'out-patient', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-03-03 13:50:16', 'pending', NULL),
('f818275a-ce49-4518-847f-a3e2722ef106', '9045-2', 'Isa Adam', 'King', 'Dr James King', 'Ward Round.\n\nPatient seen. 9DPO\n\nA case of T12/L1 wedge collapse with myelopathy.\n\nHe had T11/T12/L2/L3 PSF + Laminectomy surgery\n\nStable and calm.\n\nNFC today.\n\no/e: GC stable, not pale, afebrile, acyanosed, anicteric, not dehydrated, nil pedal edema.\n\nOp-site --Clean and dry\nPR=84b/m, 130/80mmHg\n\nSpO2--97% in room air\n\nAss: Stable', 'Discharge home on his current oral medications...\nContinue physiotherapy as an outpatient\nSee Dr MK Abubakar in 1/52 as follow up.\n', 'admit', '', '', 'pending', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-02-22 12:41:11', 'pending', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `contacts`
--

CREATE TABLE `contacts` (
  `id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL,
  `firstname` varchar(255) DEFAULT NULL,
  `lastname` varchar(255) DEFAULT NULL,
  `message` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `daily_register`
--

CREATE TABLE `daily_register` (
  `code` int(11) NOT NULL,
  `day` date NOT NULL,
  `amount` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `department`
--

CREATE TABLE `department` (
  `id` int(11) NOT NULL,
  `dept_name` varchar(50) NOT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `facilityId` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `diagnosis`
--

CREATE TABLE `diagnosis` (
  `facilityId` varchar(50) NOT NULL,
  `vital_weight` varchar(10) DEFAULT NULL,
  `vital_height` varchar(10) DEFAULT NULL,
  `headcircumference` varchar(50) DEFAULT NULL,
  `muac` varchar(50) DEFAULT NULL,
  `tempreture` varchar(10) DEFAULT NULL,
  `pulse` varchar(10) DEFAULT NULL,
  `bloodpressure` varchar(15) DEFAULT NULL,
  `respiratory` varchar(15) DEFAULT NULL,
  `nutrition` varchar(50) DEFAULT NULL,
  `immunization` varchar(200) DEFAULT NULL,
  `development` varchar(200) DEFAULT NULL,
  `pbnh` varchar(200) DEFAULT NULL,
  `generalexamination` varchar(500) DEFAULT NULL,
  `cvs` varchar(50) DEFAULT NULL,
  `cns` varchar(50) DEFAULT NULL,
  `mss` varchar(50) DEFAULT NULL,
  `abdomen` varchar(50) DEFAULT NULL,
  `problem1` varchar(2000) DEFAULT NULL,
  `problem2` varchar(2000) DEFAULT NULL,
  `problem3` varchar(2000) DEFAULT NULL,
  `problem4` varchar(2000) DEFAULT NULL,
  `problem5` varchar(2000) DEFAULT NULL,
  `provisionalDiagnosis1` varchar(2000) DEFAULT NULL,
  `provisionalDiagnosis2` varchar(2000) DEFAULT NULL,
  `provisionalDiagnosis3` varchar(2000) DEFAULT NULL,
  `provisionalDiagnosis4` varchar(2000) DEFAULT NULL,
  `provisionalDiagnosis5` varchar(2000) DEFAULT NULL,
  `addedcare` varchar(2000) DEFAULT NULL,
  `partToDress` varchar(500) DEFAULT NULL,
  `dresswith` varchar(500) DEFAULT NULL,
  `seen_by` varchar(50) DEFAULT NULL,
  `patient_id` varchar(50) NOT NULL,
  `date` datetime DEFAULT current_timestamp(),
  `status` varchar(50) DEFAULT NULL,
  `appointment_date` datetime DEFAULT NULL,
  `comment` varchar(150) DEFAULT NULL,
  `pastSurgicalHistory` varchar(500) DEFAULT NULL,
  `social` varchar(400) DEFAULT NULL,
  `otherSocialHistory` varchar(2000) DEFAULT NULL,
  `obtsGyneaHistory` varchar(2000) DEFAULT NULL,
  `pasttMedicalHistory` varchar(2000) DEFAULT NULL,
  `allergy` varchar(60) DEFAULT NULL,
  `otherAllergies` varchar(2000) DEFAULT NULL,
  `drugHistory` varchar(2000) DEFAULT NULL,
  `otherSysExamination` varchar(2000) DEFAULT NULL,
  `respiratoryRate` varchar(20) DEFAULT NULL,
  `athropometry_height` varchar(10) DEFAULT NULL,
  `presenting_complaints` varchar(2000) DEFAULT NULL,
  `athropometry_weight` varchar(10) DEFAULT NULL,
  `id` int(11) NOT NULL,
  `BMR` varchar(5) DEFAULT NULL,
  `BVR` varchar(5) DEFAULT NULL,
  `LLL` varchar(5) DEFAULT NULL,
  `RLL` varchar(5) DEFAULT NULL,
  `LUL` varchar(5) DEFAULT NULL,
  `RUL` varchar(5) NOT NULL,
  `management_plan` varchar(2000) DEFAULT NULL,
  `asthmatic` varchar(5) DEFAULT NULL,
  `dehydration` varchar(20) DEFAULT NULL,
  `diabetic` varchar(5) DEFAULT NULL,
  `diabeticRegularOnMedication` varchar(50) DEFAULT NULL,
  `hypertensive` varchar(5) DEFAULT NULL,
  `hypertensiveDuration` varchar(50) DEFAULT NULL,
  `eye_opening` varchar(5) DEFAULT NULL,
  `others` varchar(50) DEFAULT NULL,
  `palor` varchar(5) DEFAULT NULL,
  `pastMedicalHistory` varchar(200) DEFAULT NULL,
  `observation_request` varchar(2000) DEFAULT NULL,
  `hypertensiveRegularOnMedication` varchar(50) DEFAULT NULL,
  `optimalSugarControl` varchar(50) DEFAULT NULL,
  `drugAllergy` varchar(50) DEFAULT NULL,
  `dressing_request` varchar(500) DEFAULT NULL,
  `nursing_request` varchar(500) DEFAULT NULL,
  `nursing_request_status` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `diagnosis`
--

INSERT INTO `diagnosis` (`facilityId`, `vital_weight`, `vital_height`, `headcircumference`, `muac`, `tempreture`, `pulse`, `bloodpressure`, `respiratory`, `nutrition`, `immunization`, `development`, `pbnh`, `generalexamination`, `cvs`, `cns`, `mss`, `abdomen`, `problem1`, `problem2`, `problem3`, `problem4`, `problem5`, `provisionalDiagnosis1`, `provisionalDiagnosis2`, `provisionalDiagnosis3`, `provisionalDiagnosis4`, `provisionalDiagnosis5`, `addedcare`, `partToDress`, `dresswith`, `seen_by`, `patient_id`, `date`, `status`, `appointment_date`, `comment`, `pastSurgicalHistory`, `social`, `otherSocialHistory`, `obtsGyneaHistory`, `pasttMedicalHistory`, `allergy`, `otherAllergies`, `drugHistory`, `otherSysExamination`, `respiratoryRate`, `athropometry_height`, `presenting_complaints`, `athropometry_weight`, `id`, `BMR`, `BVR`, `LLL`, `RLL`, `LUL`, `RUL`, `management_plan`, `asthmatic`, `dehydration`, `diabetic`, `diabeticRegularOnMedication`, `hypertensive`, `hypertensiveDuration`, `eye_opening`, `others`, `palor`, `pastMedicalHistory`, `observation_request`, `hypertensiveRegularOnMedication`, `optimalSugarControl`, `drugAllergy`, `dressing_request`, `nursing_request`, `nursing_request_status`) VALUES
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', NULL, 'undefined', 'undefined', 'abdurrahman', '3491-2', '2021-09-29 19:58:00', 'seen', NULL, NULL, 'undefined', 'undefined', 'undefined', 'undefined', NULL, 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'Patient had meningioma surgery about 3 weeks ago, and now they admitted on account of a brain abscess. \n\nShe had surgery a few days ago and currently on rehabilitation.\n\n\n\n', 'undefined', 1, 'undef', NULL, 'undef', 'undef', NULL, 'undef', 'undefined', 'undef', 'undefined', 'undef', NULL, 'undef', 'undefined', 'undef', 'undefined', 'undef', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', NULL, NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', NULL, 'undefined', 'undefined', 'abdurrahman', '5840-1', '2021-09-29 20:19:01', 'seen', NULL, NULL, 'undefined', 'undefined', 'undefined', 'undefined', NULL, 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'Had meningioma surgery a few weeks ago, now presenting with an abcess.', 'undefined', 2, 'undef', NULL, 'undef', 'undef', NULL, 'undef', 'undefined', 'undef', 'undefined', 'undef', NULL, 'undef', 'undefined', 'undef', 'undefined', 'undef', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', NULL, NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', NULL, 'undefined', 'undefined', 'abdurrahman', '3491-2', '2021-09-29 20:58:37', 'seen', NULL, NULL, 'undefined', 'undefined', 'undefined', 'undefined', NULL, 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', '', 'undefined', 3, 'undef', NULL, 'undef', 'undef', NULL, 'undef', 'undefined', 'undef', 'undefined', 'undef', NULL, 'undef', 'undefined', 'undef', 'undefined', 'undef', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', NULL, NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', NULL, 'undefined', 'undefined', 'abdurrahman', '5840-1', '2021-09-29 21:01:51', 'seen', NULL, NULL, 'undefined', 'undefined', 'undefined', 'undefined', NULL, 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', '', 'undefined', 4, 'undef', NULL, 'undef', 'undef', NULL, 'undef', 'undefined', 'undef', 'undefined', 'undef', NULL, 'undef', 'undefined', 'undef', 'undefined', 'undef', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', NULL, NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', NULL, 'undefined', 'undefined', 'abdurrahman', '241-2', '2021-09-30 19:39:41', 'seen', NULL, NULL, 'undefined', 'undefined', 'undefined', 'undefined', NULL, 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', '', 'undefined', 24, 'undef', NULL, 'undef', 'undef', NULL, 'undef', 'undefined', 'undef', 'undefined', 'undef', NULL, 'undef', 'undefined', 'undef', 'undefined', 'undef', 'undefined', 'undefined', 'undefined', 'undefined', 'undefined', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `dieselrefuel`
--

CREATE TABLE `dieselrefuel` (
  `id` int(11) NOT NULL,
  `createdAt` datetime DEFAULT current_timestamp(),
  `gen` varchar(11) DEFAULT NULL,
  `quantity` varchar(11) DEFAULT NULL,
  `facilityId` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `dieselrefuel`
--

INSERT INTO `dieselrefuel` (`id`, `createdAt`, `gen`, `quantity`, `facilityId`) VALUES
(1, '2019-12-24 00:00:00', 'Gen2', '25', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(2, '2019-12-24 00:00:00', 'Gen1', '34', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(3, '2019-12-25 00:00:00', 'Gen2', '34', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(4, '2019-12-25 00:00:00', 'Gen1', '80', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `dieselusage`
--

CREATE TABLE `dieselusage` (
  `id` int(11) NOT NULL,
  `createdAt` datetime DEFAULT current_timestamp(),
  `gen` varchar(10) DEFAULT NULL,
  `time_started` time DEFAULT NULL,
  `time_stopped` time DEFAULT NULL,
  `facilityId` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `dieselusage`
--

INSERT INTO `dieselusage` (`id`, `createdAt`, `gen`, `time_started`, `time_stopped`, `facilityId`) VALUES
(1, '2019-12-22 00:00:00', 'gen1', '12:12:12', '17:45:23', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(2, '2019-12-24 00:00:00', 'Gen2', '22:12:00', '23:45:00', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(3, '2019-12-24 00:00:00', 'Gen1', '22:12:00', '22:12:00', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(4, '2019-12-24 00:00:00', 'Gen1', '22:12:00', '22:12:00', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(5, '2019-12-25 00:00:00', 'Gen2', '10:12:00', '10:12:00', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(6, '2019-12-25 00:00:00', 'Gen1', '17:12:00', '17:12:00', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `discharge_reports`
--

CREATE TABLE `discharge_reports` (
  `id` int(11) NOT NULL,
  `patient_id` varchar(50) NOT NULL,
  `report_text` text NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `discount`
--

CREATE TABLE `discount` (
  `id` int(11) NOT NULL,
  `discountName` varchar(50) NOT NULL,
  `discountType` varchar(20) NOT NULL,
  `discountAmount` int(11) NOT NULL,
  `discountHead` varchar(50) NOT NULL,
  `discountHeadName` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `facilityId` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `dispensary`
--

CREATE TABLE `dispensary` (
  `drug` varchar(40) DEFAULT NULL,
  `quantity` varchar(50) DEFAULT NULL,
  `dosage` varchar(40) DEFAULT NULL,
  `quantity_dispensed` int(11) DEFAULT NULL,
  `unit_of_issue` varchar(20) DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `amount` varchar(11) DEFAULT NULL,
  `discount` varchar(50) DEFAULT NULL,
  `total` int(50) DEFAULT NULL,
  `patient_id` varchar(11) DEFAULT NULL,
  `id` varchar(50) NOT NULL,
  `receiptNo` varchar(11) DEFAULT NULL,
  `facilityId` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `dispensed_by` varchar(50) DEFAULT NULL,
  `prescribed_by` varchar(50) DEFAULT NULL,
  `duration` varchar(20) DEFAULT NULL,
  `period` varchar(20) DEFAULT NULL,
  `no_of_days` int(11) DEFAULT NULL,
  `frequency` varchar(20) DEFAULT NULL,
  `receipt_no` varchar(50) DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `schedule_status` varchar(50) NOT NULL DEFAULT 'pending',
  `request_id` varchar(50) NOT NULL,
  `drug_id` varchar(100) DEFAULT NULL,
  `route` varchar(20) NOT NULL,
  `additionalInfo` varchar(500) DEFAULT NULL,
  `decision` varchar(20) NOT NULL,
  `drugCount` varchar(10) NOT NULL,
  `startTime` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `times_per_day` int(11) NOT NULL,
  `end_date` datetime DEFAULT NULL,
  `no_times` int(11) NOT NULL,
  `branch_name` varchar(50) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `dispensary`
--

INSERT INTO `dispensary` (`drug`, `quantity`, `dosage`, `quantity_dispensed`, `unit_of_issue`, `price`, `amount`, `discount`, `total`, `patient_id`, `id`, `receiptNo`, `facilityId`, `created_at`, `dispensed_by`, `prescribed_by`, `duration`, `period`, `no_of_days`, `frequency`, `receipt_no`, `expiry_date`, `status`, `schedule_status`, `request_id`, `drug_id`, `route`, `additionalInfo`, `decision`, `drugCount`, `startTime`, `times_per_day`, `end_date`, `no_times`, `branch_name`) VALUES
('Levofloxacin', '1', '4', NULL, NULL, NULL, NULL, NULL, NULL, '35-1', '9763d4d7-d382-4742-8a8d-c6ea24375c4d', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-08-27 10:47:45', 'abdurrahman', 'abdurrahman', '1', 'days', 1, '12 Hourly', NULL, NULL, 'Dispense', 'scheduled', 'cbdb8689-7d29-44e5-bb52-cd7d83ddcf91', '1', 'IV', '', 'admit', '2', '2025-08-27 10:47:57', 2, '2025-08-28 18:00:00', 12, 'Prime Pharmacy'),
('Levofloxacin', '11', '4', NULL, NULL, NULL, NULL, NULL, NULL, '35-1', '55f9a351-c878-46ec-b32b-fc4eaa2b68b2', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-09-04 12:31:19', 'abdurrahman', 'abdurrahman', '1', 'days', 1, '12 Hourly', NULL, NULL, 'Dispense', 'scheduled', '1cf84f0d-073f-4f89-925a-3d41d1020380', '1', 'IV', '', 'admit', '2', '2025-09-04 12:32:39', 2, '2025-09-05 18:00:00', 12, 'Prime Pharmacy'),
('Levofloxacin', NULL, '4', NULL, NULL, NULL, NULL, NULL, NULL, '28-1', 'd948ebb3-6220-4a73-8ecf-c6a7137ff76f', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-09-04 12:31:38', NULL, 'abdurrahman', '1', 'days', 1, '12 Hourly', NULL, NULL, 'request', 'pending', '392548ad-6e07-4f5b-b360-0c95e8c4234f', '1', 'IV', '', 'out-patient', '2', '2025-09-04 18:00:00', 2, '2025-09-05 18:00:00', 12, NULL),
('Levofloxacin', NULL, '4', NULL, NULL, NULL, NULL, NULL, NULL, '25-1', 'c389e9be-4d0d-47d2-b8d4-9189a4d0ac47', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-07 14:40:30', NULL, 'abdurrahman', '1', 'days', 1, '12 Hourly', NULL, NULL, 'request', 'scheduled', '', 'c389e9be-4d0d-47d2-b8d4-9189a4d0ac47', 'IV', '', 'outpatient', '2', '2025-10-07 14:40:30', 2, '2025-10-08 18:00:00', 12, NULL),
('Menthodex', NULL, '2', NULL, NULL, NULL, NULL, NULL, NULL, '37-1', 'eba3be86-67d4-495c-97f6-1e3767338654', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 09:08:38', NULL, 'abdurrahman', '1', 'days', 1, '12 Hourly', NULL, NULL, 'request', 'pending', 'ohuj0i8gkt9', 'Menthodex', 'IM', '', 'null', '0', '2025-10-30 09:08:38', 0, '2025-10-31 09:08:38', 0, NULL),
('Levofloxacin', NULL, '4', NULL, NULL, NULL, NULL, NULL, NULL, '37-1', '5011f225-c0b0-4242-82ba-917554dadbc9', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 09:09:15', NULL, 'abdurrahman', '1', 'days', 1, '12 Hourly', NULL, NULL, 'request', 'pending', '4765056d-1cf2-4222-ba4b-57399efb1823', '1', 'IV', '', 'out-patient', '2', '2025-10-30 18:00:00', 2, '2025-10-31 18:00:00', 12, NULL),
('Levofloxacin', NULL, '4', NULL, NULL, NULL, NULL, NULL, NULL, '33-1', '0faa6602-bd9f-417e-a576-29d68b5c8b82', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 09:36:13', NULL, 'abdurrahman', '1', 'days', 1, '12 Hourly', NULL, NULL, 'request', 'pending', 'e64b47ba-a421-4d38-aee5-f9ea735ef992', '1', 'IV', '', 'out-patient', '2', '2025-10-30 18:00:00', 2, '2025-10-31 18:00:00', 12, NULL),
('Levofloxacin', NULL, '4', NULL, NULL, NULL, NULL, NULL, NULL, '33-1', '6f0dacaf-e172-42f3-8ede-a026ce39d9cf', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 09:43:05', NULL, 'abdurrahman', '1', 'days', 1, '12 Hourly', NULL, NULL, 'request', 'pending', '7fb85acd-e2c4-4dca-8a77-0ca36be2a10e', '1', 'IV', '', 'out-patient', '2', '2025-10-30 18:00:00', 2, '2025-10-31 18:00:00', 12, NULL),
('Levofloxacin', NULL, '4', NULL, NULL, NULL, NULL, NULL, NULL, '33-1', '7150c9c2-c6c3-4aef-974d-4ceac5e0482c', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 09:45:16', NULL, 'abdurrahman', '1', 'days', 1, '12 Hourly', NULL, NULL, 'request', 'pending', 'b1f56ecc-ef21-432c-86a1-8db4860bc6e5', '1', 'IV', '', 'out-patient', '2', '2025-10-30 18:00:00', 2, '2025-10-31 18:00:00', 12, NULL),
('Levofloxacin', NULL, '4', NULL, NULL, NULL, NULL, NULL, NULL, '35-1', '2f4b322e-7eaf-44b9-be73-7f68482daf85', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 10:25:58', NULL, 'abdurrahman', '1', 'days', 1, '12 Hourly', NULL, NULL, 'request', 'scheduled', 'cd21cfea-9cc0-4263-9424-187372f453f1', '1', 'IV', '', 'admit', '2', '2025-10-30 10:25:58', 2, '2025-10-31 18:00:00', 12, NULL),
('Menthodex', NULL, '20mg', NULL, NULL, NULL, NULL, NULL, NULL, '2-1', 'debf6bc6-665f-467c-8f43-46910e5ab6df', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:18:52', NULL, 'abdurrahman', '4', 'days', 4, '12 Hourly', NULL, NULL, 'request', 'pending', '586a9658-82df-4ea7-a95b-1ee1dcf154fc', '4', 'IM', '', 'out-patient', '8', '2026-01-09 18:00:00', 2, '2026-01-13 18:00:00', 12, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `doctor_entries`
--

CREATE TABLE `doctor_entries` (
  `doc_acct` varchar(50) DEFAULT NULL,
  `dr` int(11) DEFAULT NULL,
  `cr` int(11) DEFAULT NULL,
  `reference_no` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `facilityId` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `createdAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `druglist`
--

CREATE TABLE `druglist` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `generic_name` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `druglist`
--

INSERT INTO `druglist` (`id`, `name`, `generic_name`, `created_at`) VALUES
(1, 'Levofloxacin', '', '2021-09-29 18:52:50'),
(2, 'Dalcin C', 'Clindamycin', '2021-09-29 18:52:50'),
(4, 'Menthodex', '', '2021-09-29 19:12:25'),
(325, 'Midazolam', 'Midazolam', '2021-10-22 10:32:27'),
(327, 'Amatem Tabs', 'Arthemether/Lumefantrine', '2021-10-22 10:48:21'),
(329, 'Testing', 'TTT', '2025-11-12 12:07:57');

-- --------------------------------------------------------

--
-- Table structure for table `drugpurchaserecords`
--

CREATE TABLE `drugpurchaserecords` (
  `drug_code` varchar(50) NOT NULL,
  `drug` varchar(30) NOT NULL,
  `generic_name` varchar(100) NOT NULL,
  `unit_of_issue` varchar(100) NOT NULL,
  `reorder_level` int(11) NOT NULL,
  `cost_price` varchar(50) NOT NULL,
  `markUp` varchar(50) NOT NULL,
  `quantity` int(11) DEFAULT 0,
  `by_whom` varchar(100) DEFAULT NULL,
  `supplier` varchar(40) NOT NULL,
  `receipt_no` varchar(20) DEFAULT NULL,
  `payment_status` varchar(10) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `receipt_picture` blob DEFAULT NULL,
  `expiry_date` date NOT NULL,
  `expiry_alert` int(5) NOT NULL,
  `balance` varchar(50) DEFAULT NULL,
  `dispensary_balance` int(11) NOT NULL,
  `shift` varchar(20) NOT NULL,
  `status` varchar(10) NOT NULL,
  `facilityId` varchar(50) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `drugpurchaserecords`
--

INSERT INTO `drugpurchaserecords` (`drug_code`, `drug`, `generic_name`, `unit_of_issue`, `reorder_level`, `cost_price`, `markUp`, `quantity`, `by_whom`, `supplier`, `receipt_no`, `payment_status`, `created_at`, `receipt_picture`, `expiry_date`, `expiry_alert`, `balance`, `dispensary_balance`, `shift`, `status`, `facilityId`) VALUES
('', 'Tabs Levofloxacin', '', '0', 0, '350', '1150', 20, 'abdurrahman', '72', '0', 'paid', '2021-09-29 19:52:50', NULL, '2023-01-29', 0, NULL, 20, '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Tabs Dalcin C', 'Clindamycin', '0', 0, '850', '500', 20, 'abdurrahman', '72', '0', 'paid', '2021-09-29 19:52:50', NULL, '2023-01-29', 0, NULL, 11, '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Panadol caplets', 'Paracetamol', '0', 0, '120', '0', 100, 'Abdulrauf', '74', '0', 'paid', '2021-10-22 11:55:25', NULL, '2024-10-22', 0, NULL, 100, '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

--
-- Triggers `drugpurchaserecords`
--
DELIMITER $$
CREATE TRIGGER `after_dispensary_quantity_and_markup_edit` AFTER UPDATE ON `drugpurchaserecords` FOR EACH ROW BEGIN
    IF OLD.dispensary_balance <> new.dispensary_balance OR OLD.markUp <> new.markUp THEN
        INSERT INTO audit_trail(id,drug_name,facilityId,	old_dispensary_balance,new_dispensary_balance,old_markup,new_markup,source_table,updated_by)
        VALUES(old.drug_code,old.drug, old.facilityId, old.dispensary_balance,new.dispensary_balance, old.markUp,new.markUp, 'drugpurchaserecords', new.by_whom);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `drugs`
--

CREATE TABLE `drugs` (
  `drug_code` varchar(50) NOT NULL,
  `drug` varchar(20) DEFAULT NULL,
  `expiry_date` varchar(10) DEFAULT NULL,
  `price` int(10) NOT NULL DEFAULT 0,
  `unit_of_issue` varchar(20) DEFAULT '0',
  `qty_in` int(11) NOT NULL,
  `qty_out` int(11) NOT NULL,
  `source` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `supplier` varchar(100) DEFAULT NULL,
  `receipt_no` varchar(11) NOT NULL DEFAULT '0',
  `store_award_no` int(10) NOT NULL DEFAULT 0,
  `created_by` varchar(30) DEFAULT NULL,
  `receipt_image` blob DEFAULT NULL,
  `genericName` varchar(50) DEFAULT NULL,
  `markup` int(11) NOT NULL,
  `client_acct` varchar(50) NOT NULL,
  `shift` varchar(20) NOT NULL,
  `facilityId` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `drugs`
--

INSERT INTO `drugs` (`drug_code`, `drug`, `expiry_date`, `price`, `unit_of_issue`, `qty_in`, `qty_out`, `source`, `created_at`, `supplier`, `receipt_no`, `store_award_no`, `created_by`, `receipt_image`, `genericName`, `markup`, `client_acct`, `shift`, `facilityId`) VALUES
('', 'Pregabalin', '2023-01-29', 100, '0', 0, 10, 'purchases', '2021-09-29 18:52:50', '72', '29092118112', 0, 'abdurrahman', NULL, 'Pregabalin', 10, '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Tabs Dalcin C', '2023-01-29', 1000, '0', 0, 20, 'purchases', '2021-09-29 18:52:50', '72', '29092118112', 0, 'abdurrahman', NULL, 'Clindamycin', 100, '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Tabs Levofloxacin', '2023-01-29', 500, '0', 0, 20, 'purchases', '2021-09-29 18:52:50', '72', '29092118112', 0, 'abdurrahman', NULL, '', 50, '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Torsemide ', '2222-02-22', 1111, '', 56, 0, 'sold_items', '2021-11-06 11:55:28', '72', '06112112125', 0, 'Maryam', NULL, 'Torsemide', 0, '5592', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Torsemide ', '2222-02-22', 1111, '', 0, 56, 'dispensary', '2021-11-06 11:55:28', '72', '06112112125', 0, 'Maryam', NULL, 'Torsemide', 0, '5592', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Losartan', '2023-12-01', 1200, '', 56, 0, 'sold_items', '2021-11-06 11:55:28', '72', '06112112125', 0, 'Maryam', NULL, 'Losartan', 0, '5592', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Losartan', '2023-12-01', 1200, '', 0, 56, 'dispensary', '2021-11-06 11:55:28', '72', '06112112125', 0, 'Maryam', NULL, 'Losartan', 0, '5592', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Clopidogrel', '2222-11-22', 1400, '', 56, 0, 'sold_items', '2021-11-06 11:55:29', '72', '06112112125', 0, 'Maryam', NULL, 'Clopidogrel', 0, '5592', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Clopidogrel', '2222-11-22', 1400, '', 0, 56, 'dispensary', '2021-11-06 11:55:29', '72', '06112112125', 0, 'Maryam', NULL, 'Clopidogrel', 0, '5592', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Omeprazole', '2023-09-01', 1200, '', 1, 0, 'sold_items', '2021-11-06 11:56:10', '72', '06112113125', 0, 'Maryam', NULL, 'Omeprazole', 0, '6176', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Omeprazole', '2023-09-01', 1200, '', 0, 1, 'dispensary', '2021-11-06 11:56:10', '72', '06112113125', 0, 'Maryam', NULL, 'Omeprazole', 0, '6176', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Hyoscine ', '2023-06-04', 700, '', 1, 0, 'sold_items', '2021-11-06 11:56:10', '72', '06112113125', 0, 'Maryam', NULL, 'buscopam 20mg', 0, '6176', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Hyoscine ', '2023-06-04', 700, '', 0, 1, 'dispensary', '2021-11-06 11:56:10', '72', '06112113125', 0, 'Maryam', NULL, 'buscopam 20mg', 0, '6176', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Hyoscine ', '2022-10-22', 800, '', 1, 0, 'sold_items', '2021-11-06 11:56:10', '72', '06112113125', 0, 'Maryam', NULL, 'colipan', 0, '6176', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Hyoscine ', '2022-10-22', 800, '', 0, 1, 'dispensary', '2021-11-06 11:56:10', '72', '06112113125', 0, 'Maryam', NULL, 'colipan', 0, '6176', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Menthodex', '2023-01-29', 1100, '', 1, 0, 'sold_items', '2021-11-06 22:33:20', '', '07112125126', 0, 'Maryam', NULL, '', 0, '329', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Menthodex', '2023-01-29', 1100, '', 0, 1, 'dispensary', '2021-11-06 22:33:20', '', '07112125126', 0, 'Maryam', NULL, '', 0, '329', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Cefpodoxime', '2022-05-01', 2800, '', 1, 0, 'sold_items', '2021-11-06 22:33:20', '', '07112125126', 0, 'Maryam', NULL, '', 0, '329', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'Cefpodoxime', '2022-05-01', 2800, '', 0, 1, 'dispensary', '2021-11-06 22:33:20', '', '07112125126', 0, 'Maryam', NULL, '', 0, '329', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'oxymet nasal drop', '2022-06-01', 0, '', 1, 0, 'sold_items', '2021-11-06 22:33:20', '', '07112125126', 0, 'Maryam', NULL, '', 0, '329', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
('', 'oxymet nasal drop', '2022-06-01', 0, '', 0, 1, 'dispensary', '2021-11-06 22:33:20', '', '07112125126', 0, 'Maryam', NULL, '', 0, '329', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `drug_frequency`
--

CREATE TABLE `drug_frequency` (
  `id` int(11) NOT NULL,
  `description` varchar(20) NOT NULL,
  `time_start` time DEFAULT NULL,
  `interval_` int(11) DEFAULT NULL,
  `interval_uom` varchar(10) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `drug_frequency`
--

INSERT INTO `drug_frequency` (`id`, `description`, `time_start`, `interval_`, `interval_uom`) VALUES
(1, 'Once Daily', '10:00:00', 24, 'hour'),
(2, '12 Hourly', '06:00:00', 12, 'hour'),
(3, '8 hourly', '06:00:00', 8, 'hour'),
(4, '6 Hourly', '06:00:00', 6, 'hour'),
(5, '4 Hourly', '12:00:00', 4, 'hour'),
(6, 'STAT', NULL, 24, 'hour'),
(7, 'PRN', NULL, NULL, ''),
(8, 'Nocte', '20:00:00', 24, 'hour');

-- --------------------------------------------------------

--
-- Table structure for table `drug_frequency4`
--

CREATE TABLE `drug_frequency4` (
  `id` int(11) NOT NULL,
  `description` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `time` varchar(20) DEFAULT NULL,
  `drug_time` int(11) NOT NULL,
  `no_times` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `drug_frequency4`
--

INSERT INTO `drug_frequency4` (`id`, `description`, `time`, `drug_time`, `no_times`) VALUES
(27, '12 Hourly', '06:00', 6, 12),
(28, '12 Hourly', '18:00', 18, 12),
(30, 'Once Daily', '10:00', 10, 24),
(31, '8 Hourly', '06:00', 6, 8),
(32, '8 Hourly', '14:00', 14, 8),
(33, '8 Hourly', '22:00', 22, 8),
(34, '6 Hourly', '06:00', 6, 6),
(35, '6 Hourly', '12:00', 12, 6),
(36, '6 Hourly', '18:00', 18, 6),
(37, '6 Hourly', '00:00', 0, 6),
(38, '4 Hourly', '00:00', 0, 4),
(39, '4 Hourly', '04:00', 4, 4),
(40, '4 Hourly', '08:00', 8, 4),
(41, '4 Hourly', '12:00', 12, 4),
(42, '4 Hourly', '16:00', 16, 4),
(43, '4 Hourly', '20:00', 20, 4),
(44, 'STAT', '08:00', 8, 24),
(46, 'PRN', '06:00', 6, 24),
(47, 'Nocte', '22:00', 22, 0),
(48, '900 time monthly', '04:00', 4, 0),
(49, '900 time monthly', '01:00', 1, 0),
(50, 'Testing', '00:00', 0, 0),
(51, 'Testing', '01:00', 1, 0),
(52, 'New Hourly', '07:00', 7, 0),
(53, 'New Hourly', '19:00', 19, 0);

-- --------------------------------------------------------

--
-- Table structure for table `drug_frequency4_x`
--

CREATE TABLE `drug_frequency4_x` (
  `id` int(11) NOT NULL,
  `description` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `time` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `drug_frequency4_x`
--

INSERT INTO `drug_frequency4_x` (`id`, `description`, `time`) VALUES
(5, 'Once Daily', '10am'),
(6, '12 Hourly', '6am'),
(7, '12 Hourly', '6pm'),
(8, '8 Hourly', '6am'),
(9, '8 Hourly', '2pm'),
(10, '8 Hourly', '6pm'),
(11, '6 Hourly', '6am'),
(12, '6 Hourly', '12pm'),
(13, '6 Hourly', '6pm'),
(14, '6 Hourly', '12am'),
(15, '4 Hourly', '12pm'),
(16, '4 Hourly', '4pm'),
(17, '4 Hourly', '8pm'),
(18, '4 Hourly', '12am'),
(19, '4 Hourly', '4am'),
(20, '4 Hourly', '8am'),
(21, 'STAT', '8am'),
(22, 'Nocte', '8pm');

-- --------------------------------------------------------

--
-- Table structure for table `drug_frequency4_y`
--

CREATE TABLE `drug_frequency4_y` (
  `id` int(11) NOT NULL,
  `description` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `time` varchar(20) DEFAULT NULL,
  `drug_time` int(11) NOT NULL,
  `no_times` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `drug_frequency4_y`
--

INSERT INTO `drug_frequency4_y` (`id`, `description`, `time`, `drug_time`, `no_times`) VALUES
(27, '12 Hourly', '06:00', 6, 0),
(28, '12 Hourly', '18:00', 18, 0),
(30, 'Once Daily', '10:00', 10, 0),
(31, '8 Hourly', '06:00', 6, 0),
(32, '8 Hourly', '14:00', 14, 0),
(33, '8 Hourly', '22:00', 22, 0),
(34, '6 Hourly', '06:00', 6, 0),
(35, '6 Hourly', '12:00', 12, 0),
(36, '6 Hourly', '18:00', 18, 0),
(37, '6 Hourly', '00:00', 0, 0),
(38, '4 Hourly', '00:00', 0, 0),
(39, '4 Hourly', '04:00', 4, 0),
(40, '4 Hourly', '08:00', 8, 0),
(41, '4 Hourly', '12:00', 12, 0),
(42, '4 Hourly', '16:00', 16, 0),
(43, '4 Hourly', '20:00', 20, 0),
(44, 'STAT', '08:00', 8, 0),
(45, 'Nocte', '22:00', 22, 0);

-- --------------------------------------------------------

--
-- Table structure for table `drug_interaction`
--

CREATE TABLE `drug_interaction` (
  `id` int(11) NOT NULL,
  `event` varchar(100) NOT NULL,
  `severity` varchar(50) NOT NULL,
  `details` text DEFAULT NULL,
  `resource` varchar(50) NOT NULL,
  `resource_id` int(11) NOT NULL,
  `destination_url` varchar(500) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `drug_interaction`
--

INSERT INTO `drug_interaction` (`id`, `event`, `severity`, `details`, `resource`, `resource_id`, `destination_url`, `status`, `created_at`, `updated_at`) VALUES
(4, 'DrugInteraction', 'Moderate', 'Drug interaction detected', 'Encounter', 190, '', 'acknowledged', '2025-11-22 19:20:30', '2025-11-22 20:00:16'),
(5, 'DrugInteraction', 'Major', 'Drug interaction detected', 'Encounter', 190, '', 'acknowledged', '2025-11-22 19:23:05', '2025-11-22 19:23:50'),
(6, 'DrugInteraction', 'Major', 'Drug interaction detected', 'Encounter', 180, '', 'acknowledged', '2025-11-22 20:04:35', '2025-11-22 20:17:21'),
(7, 'DrugInteraction', 'Minor', 'Drug interaction detected', 'Encounter', 180, '', 'pending', '2025-11-22 20:26:26', '2025-11-22 20:26:26'),
(8, 'DrugInteraction', 'Minor', 'Drug interaction detected', 'Encounter', 206, '', 'acknowledged', '2025-11-22 20:28:26', '2025-11-22 20:28:51'),
(9, 'DrugInteraction', 'major', 'Drug interaction detected', 'Encounter', 206, '', 'acknowledged', '2025-11-22 20:31:55', '2025-11-22 20:34:05'),
(10, 'DrugInteraction', 'unknow', 'Drug interaction detecteds', 'Encounter', 206, '', 'acknowledged', '2025-11-22 20:36:10', '2025-11-22 20:56:19');

-- --------------------------------------------------------

--
-- Table structure for table `drug_schedule`
--

CREATE TABLE `drug_schedule` (
  `id` int(11) NOT NULL,
  `allocation_id` varchar(50) DEFAULT NULL,
  `patient_id` varchar(50) NOT NULL,
  `prescription_id` varchar(50) NOT NULL,
  `drug_name` varchar(50) NOT NULL,
  `time_stamp` timestamp NULL DEFAULT NULL,
  `status` varchar(10) NOT NULL DEFAULT 'scheduled',
  `administered_by` varchar(50) NOT NULL,
  `facilityId` varchar(50) NOT NULL,
  `served_by` varchar(50) DEFAULT NULL,
  `stopped_by` varchar(50) NOT NULL,
  `reason` varchar(500) DEFAULT NULL,
  `frequency` varchar(50) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `drug_schedule`
--

INSERT INTO `drug_schedule` (`id`, `allocation_id`, `patient_id`, `prescription_id`, `drug_name`, `time_stamp`, `status`, `administered_by`, `facilityId`, `served_by`, `stopped_by`, `reason`, `frequency`) VALUES
(1, NULL, '21-1', '228d48e7-2f47-4134-b77a-341172ed17be', 'Levofloxacin', '2025-07-30 18:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(2, NULL, '21-1', '228d48e7-2f47-4134-b77a-341172ed17be', 'Levofloxacin', '2025-07-31 06:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(3, NULL, '1-64', 'd198a93c-fc15-4f6e-8480-bc38fefe19d7', 'Levofloxacin', '2025-08-10 18:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(4, NULL, '1-64', 'd198a93c-fc15-4f6e-8480-bc38fefe19d7', 'Levofloxacin', '2025-08-11 06:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(5, NULL, '31-1', '839e71df-4c95-4dcc-8b38-9d54089cbf10', 'Levofloxacin', '2025-08-11 18:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(6, NULL, '31-1', '839e71df-4c95-4dcc-8b38-9d54089cbf10', 'Levofloxacin', '2025-08-12 06:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(7, NULL, '35-1', '9763d4d7-d382-4742-8a8d-c6ea24375c4d', 'Levofloxacin', '2025-08-27 18:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(8, NULL, '35-1', '9763d4d7-d382-4742-8a8d-c6ea24375c4d', 'Levofloxacin', '2025-08-28 06:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(9, NULL, '35-1', '55f9a351-c878-46ec-b32b-fc4eaa2b68b2', 'Levofloxacin', '2025-09-04 18:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(10, NULL, '35-1', '55f9a351-c878-46ec-b32b-fc4eaa2b68b2', 'Levofloxacin', '2025-09-05 06:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(11, NULL, '25-1', 'c389e9be-4d0d-47d2-b8d4-9189a4d0ac47', 'Levofloxacin', '2025-10-07 18:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(12, NULL, '25-1', 'c389e9be-4d0d-47d2-b8d4-9189a4d0ac47', 'Levofloxacin', '2025-10-08 06:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(13, NULL, '35-1', '2f4b322e-7eaf-44b9-be73-7f68482daf85', 'Levofloxacin', '2025-10-30 18:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL),
(14, NULL, '35-1', '2f4b322e-7eaf-44b9-be73-7f68482daf85', 'Levofloxacin', '2025-10-31 06:00:00', 'scheduled', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, '', NULL, NULL);

-- --------------------------------------------------------

--
-- Stand-in structure for view `drug_schedule_view`
-- (See below for the actual view)
--
CREATE TABLE `drug_schedule_view` (
`drug` varchar(40)
,`dosage` varchar(40)
,`patient_id` varchar(11)
,`created_at` datetime
,`id` int(11)
,`prescription_id` varchar(50)
,`prescribed_by` varchar(50)
,`duration` varchar(20)
,`period` varchar(20)
,`frequency` varchar(20)
,`route` varchar(20)
,`time_stamp` timestamp
,`administered_by` varchar(50)
,`served_by` varchar(50)
,`reason` varchar(500)
,`status` varchar(10)
,`facilityId` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `expenditure_view`
-- (See below for the actual view)
--
CREATE TABLE `expenditure_view` (
`subhead` varchar(50)
,`description` varchar(225)
,`modeOfPayment` varchar(50)
,`acct` varchar(100)
,`createdAt` datetime
,`amount` int(50)
,`facilityId` varchar(50)
,`client_acct` varchar(200)
,`enteredBy` varchar(20)
);

-- --------------------------------------------------------

--
-- Table structure for table `feedbacks`
--

CREATE TABLE `feedbacks` (
  `id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL,
  `userId` varchar(255) DEFAULT NULL,
  `message` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `feedbacks`
--

INSERT INTO `feedbacks` (`id`, `userId`, `message`, `createdAt`, `updatedAt`) VALUES
('c0394335-c2a3-4cde-82a9-1fefcb8bf9bd', 'zaks', 'please come an see something  on micro biology', '2021-03-03 10:05:43', '2021-03-03 10:05:43');

-- --------------------------------------------------------

--
-- Table structure for table `fluid_chart`
--

CREATE TABLE `fluid_chart` (
  `id` int(11) NOT NULL,
  `patient_id` varchar(50) DEFAULT NULL,
  `input_volume` varchar(50) DEFAULT NULL,
  `input_route` varchar(50) DEFAULT NULL,
  `input_type` varchar(50) DEFAULT NULL,
  `output_volume` varchar(50) DEFAULT NULL,
  `output_route` varchar(60) DEFAULT NULL,
  `output_type` varchar(60) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `group_service`
--

CREATE TABLE `group_service` (
  `id` int(11) NOT NULL,
  `head` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `subhead` varchar(50) DEFAULT NULL,
  `description` varchar(100) DEFAULT NULL,
  `price` float NOT NULL,
  `quantity` float NOT NULL,
  `facilityId` varchar(55) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hmo_registration_table`
--

CREATE TABLE `hmo_registration_table` (
  `id` int(11) NOT NULL,
  `HMO_name` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `hmo_registration_table`
--

INSERT INTO `hmo_registration_table` (`id`, `HMO_name`) VALUES
(1, 'General HMOS'),
(2, 'Reliance HMO');

-- --------------------------------------------------------

--
-- Table structure for table `hospitals`
--

CREATE TABLE `hospitals` (
  `id` varchar(50) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `admin` varchar(225) DEFAULT NULL,
  `useLetterHead` varchar(10) DEFAULT NULL,
  `printTitle` varchar(100) DEFAULT NULL,
  `printSubtitle1` varchar(200) DEFAULT NULL,
  `printSubtitle2` varchar(200) DEFAULT NULL,
  `modules` varchar(100) DEFAULT NULL,
  `features` varchar(500) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `logo` varchar(200) DEFAULT NULL,
  `type` varchar(20) DEFAULT NULL,
  `hasStore` int(11) DEFAULT NULL,
  `balance` float NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `hospitals`
--

INSERT INTO `hospitals` (`id`, `name`, `code`, `address`, `admin`, `useLetterHead`, `printTitle`, `printSubtitle1`, `printSubtitle2`, `modules`, `features`, `createdAt`, `updatedAt`, `logo`, `type`, `hasStore`, `balance`) VALUES
('07c4fc06-1329-4b59-99f6-c8e135cd5219', 'Pharmacy', '', 'Kawo', 'tttt2', NULL, NULL, NULL, NULL, NULL, NULL, '2020-09-19 15:16:35', '2020-09-19 15:16:35', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', 0, 0),
('121bb692-9a44-472f-b396-b68ebf798b30', 'Brainstorm IT Solutions', '', 'No 3. Sabo Bakin Zuwo Road, Kano', 'bits', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-24 11:39:13', '2020-11-24 11:39:13', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', 0, 0),
('18ed9422-5a43-4ff6-8e76-1f7af2b8e977', 'Demo Pharmacy', 'DPH', 'No. 3 Sabo Bakin Zuwo Road, Kano', 'demo_pharm', NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-05 18:46:05', '2020-04-05 18:46:05', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', 0, 0),
('1aba07df-882a-460f-8aa2-6a162807f0cd', 'Test Pharm', '', 'Kawo', 'test2', NULL, NULL, NULL, NULL, NULL, NULL, '2020-09-14 04:59:09', '2020-09-14 04:59:09', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', 0, 0),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'CDQ Specialist Hospital Limited', 'PSC', '19 Lamido Crescent, off Tarauni, Kano', 'abdurrahman', 'yes', 'CDQ Specialist Hospital Limited', '19 Lamido Crescent, off Tarauni, Kano', '', NULL, NULL, '2020-01-06 05:23:50', '2025-11-14 16:22:56', '/uploads/logo-1763137303904-446373416.png', 'hospital', 0, 15090900),
('1d401e9f-0cb3-494d-98a5-901e0886a5c8', 'Remedix Pharmacy Ltd', '', 'Kano', 'remedix', NULL, NULL, NULL, NULL, NULL, NULL, '2020-08-23 04:56:17', '2020-08-23 04:56:17', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', NULL, 0),
('2228e653-9a90-4453-9566-785db75c15c9', 'Bits-HIS Specialist', 'BIT', 'No. 3 Sabo Bakin Zuwo Road Beside Ministry of special Dutie', 'emaitee', NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-06 07:57:39', '2020-01-06 07:57:39', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'hospital', 0, 0),
('26161120-f7b9-48e6-b4eb-5e9dc27a02b9', 'Whatever Pharmacu', '', 'Kawo', 'test2020', NULL, NULL, NULL, NULL, NULL, NULL, '2020-09-22 17:13:58', '2020-09-22 17:13:58', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', 0, 0),
('3eb31e94-6e70-4cbc-97d4-1c476983fa8d', 'Admin Pharmacy', '', 'Kano', 'testest', NULL, NULL, NULL, NULL, NULL, NULL, '2020-09-14 19:15:11', '2020-09-14 19:15:11', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', 0, 0),
('422cc2dd-861e-4ec5-9e4b-412ca033c8fe', 'RISCAN', '', 'Kano', 'riscan-admin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-12-10 15:30:49', '2020-12-10 15:30:49', 'https://res.cloudinary.com/emaitee/image/upload/v1607617793/logo192.png', 'diagnosticCenter', 1, 0),
('6c6af0c0-35ea-40d8-a928-b13a9766113a', 'My Pharmacy', 'MPH', 'Kano', 'pharm_m', NULL, NULL, NULL, NULL, NULL, NULL, '2020-07-15 09:33:36', '2020-07-15 09:33:36', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', 0, 0),
('966a89f6-05d8-4564-b319-2f8863821e75', 'OPTIMUM DIAGNOSTICS AND CLINICAL SERVICES LIMITED', 'ODC', 'Zaria Road, Kano', 'admin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-08-11 11:51:40', '2020-08-11 11:51:40', 'https://res.cloudinary.com/emaitee/image/upload/v1606851273/mylikita/logos/optimum-logo.jpg', 'diagnosticCenter', 0, 0),
('a2cc3c63-2dd3-4e64-aed4-4f4af98d17ca', 'Test Me', '', 'nigeria', 'testme', NULL, NULL, NULL, NULL, NULL, NULL, '2020-09-14 19:08:23', '2020-09-14 19:08:23', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', 0, 0),
('a60711d5-192b-4226-8b20-576246f12499', 'Test3', '', 'Kawo', 'testmysales', NULL, NULL, NULL, NULL, NULL, NULL, '2020-09-22 17:07:46', '2020-09-22 17:07:46', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', 0, 0),
('b8823207-58e1-438c-bb62-f3c6c16d8d3d', 'LUDPHA BIO TECH', 'LUD', 'Sadauna Crescent, Kano', 'isahboy01', NULL, NULL, NULL, NULL, NULL, NULL, '2020-03-13 20:00:03', '2020-03-13 20:00:03', 'https://res.cloudinary.com/emaitee/image/upload/v1584268238/ludpha_logo.png', 'pharmacy', 0, 0),
('d7dd5507-d46f-4c02-841c-f9d42476c74c', 'mylike', 'myl', 'standard st', 'bernaddoke', NULL, NULL, NULL, NULL, NULL, NULL, '2021-04-17 14:48:30', '2021-04-17 14:48:30', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'Hospital', 0, 0),
('d8d7a732-1832-4e25-9a98-e68ddc3f0b26', 'BINADAM OIL MILLS', '', 'Kano', 'admin-user', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-02 13:52:36', '2020-11-02 13:52:36', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'factory', 0, 0),
('db18f81d-8238-4f3a-a0c5-8d12ed173767', 'Test Facility', 'TFT', 'Whatsapp', 'test_admin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-09-01 07:46:36', '2020-09-01 07:46:36', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'pharmacy', NULL, 0),
('ee83be9e-5b9b-412f-81e7-95b9417c2782', 'Demo', '', '123 Kano road.', 'demo-user', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 05:06:33', '2020-11-01 05:06:33', 'https://res.cloudinary.com/emaitee/image/upload/v1583943949/bits_his_logo.png', 'hospital', 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `hour_list`
--

CREATE TABLE `hour_list` (
  `id` int(11) NOT NULL,
  `hour` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `hour_list`
--

INSERT INTO `hour_list` (`id`, `hour`) VALUES
(1, '00:00'),
(2, '01:00'),
(3, '02:00'),
(4, '03:00'),
(5, '04:00'),
(6, '05:00'),
(7, '06:00'),
(8, '07:00'),
(9, '08:00'),
(10, '09:00'),
(11, '10:00'),
(12, '11:00'),
(13, '12:00'),
(14, '13:00'),
(15, '14:00'),
(16, '15:00'),
(17, '16:00'),
(18, '17:00'),
(19, '18:00'),
(20, '19:00'),
(21, '20:00'),
(22, '21:00'),
(23, '22:00'),
(24, '23:00');

-- --------------------------------------------------------

--
-- Table structure for table `hour_list_x`
--

CREATE TABLE `hour_list_x` (
  `id` int(11) NOT NULL,
  `hour` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `hour_list_x`
--

INSERT INTO `hour_list_x` (`id`, `hour`) VALUES
(1, '12am'),
(2, '1am'),
(3, '2am'),
(4, '3am'),
(5, '4am'),
(6, '5am'),
(7, '6am'),
(8, '7am'),
(9, '8am'),
(10, '9am'),
(11, '10am'),
(12, '11am'),
(13, '12pm'),
(14, '1pm'),
(15, '2pm'),
(16, '3pm'),
(17, '4pm'),
(18, '5pm'),
(19, '6pm'),
(20, '7pm'),
(21, '8pm'),
(22, '9pm'),
(23, '10pm'),
(24, '11pm');

-- --------------------------------------------------------

--
-- Table structure for table `icd_code`
--

CREATE TABLE `icd_code` (
  `_id` varchar(255) NOT NULL,
  `code` varchar(255) NOT NULL,
  `orders` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `icd_code`
--

INSERT INTO `icd_code` (`_id`, `code`, `orders`, `name`, `description`) VALUES
('6669468621ea4eb1c8a0dc20', 'A00', '0', 'Cholera', 'Cholera'),
('6669468621ea4eb1c8a0dc21', 'A000', '1', 'Cholera due to Vibrio cholerae 01, biovar cholerae', 'Cholera due to Vibrio cholerae 01, biovar cholerae'),
('6669468621ea4eb1c8a0dc22', 'A001', '1', 'Cholera due to Vibrio cholerae 01, biovar eltor', 'Cholera due to Vibrio cholerae 01, biovar eltor'),
('6669468621ea4eb1c8a0dc23', 'A009', '1', 'Cholera, unspecified', 'Cholera, unspecified'),
('6669468621ea4eb1c8a0dc24', 'A01', '0', 'Typhoid and paratyphoid fevers', 'Typhoid and paratyphoid fevers'),
('6669468621ea4eb1c8a0dc25', 'A010', '0', 'Typhoid fever', 'Typhoid fever'),
('6669468621ea4eb1c8a0dc26', 'A0100', '1', 'Typhoid fever, unspecified', 'Typhoid fever, unspecified'),
('6669468621ea4eb1c8a0dc27', 'A0101', '1', 'Typhoid meningitis', 'Typhoid meningitis'),
('6669468621ea4eb1c8a0dc28', 'A0102', '1', 'Typhoid fever with heart involvement', 'Typhoid fever with heart involvement'),
('6669468621ea4eb1c8a0dc29', 'A0103', '1', 'Typhoid pneumonia', 'Typhoid pneumonia'),
('6669468621ea4eb1c8a0dc2a', 'A0104', '1', 'Typhoid arthritis', 'Typhoid arthritis'),
('6669468621ea4eb1c8a0dc2b', 'A0105', '1', 'Typhoid osteomyelitis', 'Typhoid osteomyelitis'),
('6669468621ea4eb1c8a0dc2c', 'A0109', '1', 'Typhoid fever with other complications', 'Typhoid fever with other complications'),
('6669468621ea4eb1c8a0dc2d', 'A011', '1', 'Paratyphoid fever A', 'Paratyphoid fever A'),
('6669468621ea4eb1c8a0dc2e', 'A012', '1', 'Paratyphoid fever B', 'Paratyphoid fever B'),
('6669468621ea4eb1c8a0dc2f', 'A013', '1', 'Paratyphoid fever C', 'Paratyphoid fever C'),
('6669468621ea4eb1c8a0dc30', 'A014', '1', 'Paratyphoid fever, unspecified', 'Paratyphoid fever, unspecified'),
('6669468621ea4eb1c8a0dc31', 'A02', '0', 'Other salmonella infections', 'Other salmonella infections'),
('6669468621ea4eb1c8a0dc32', 'A020', '1', 'Salmonella enteritis', 'Salmonella enteritis'),
('6669468621ea4eb1c8a0dc33', 'A021', '1', 'Salmonella sepsis', 'Salmonella sepsis'),
('6669468621ea4eb1c8a0dc34', 'A022', '0', 'Localized salmonella infections', 'Localized salmonella infections'),
('6669468621ea4eb1c8a0dc35', 'A0220', '1', 'Localized salmonella infection, unspecified', 'Localized salmonella infection, unspecified'),
('6669468621ea4eb1c8a0dc36', 'A0221', '1', 'Salmonella meningitis', 'Salmonella meningitis'),
('6669468621ea4eb1c8a0dc37', 'A0222', '1', 'Salmonella pneumonia', 'Salmonella pneumonia'),
('6669468621ea4eb1c8a0dc38', 'A0223', '1', 'Salmonella arthritis', 'Salmonella arthritis'),
('6669468621ea4eb1c8a0dc39', 'A0224', '1', 'Salmonella osteomyelitis', 'Salmonella osteomyelitis'),
('6669468621ea4eb1c8a0dc3a', 'A0225', '1', 'Salmonella pyelonephritis', 'Salmonella pyelonephritis'),
('6669468621ea4eb1c8a0dc3b', 'A0229', '1', 'Salmonella with other localized infection', 'Salmonella with other localized infection'),
('6669468621ea4eb1c8a0dc3c', 'A028', '1', 'Other specified salmonella infections', 'Other specified salmonella infections'),
('6669468621ea4eb1c8a0dc3d', 'A029', '1', 'Salmonella infection, unspecified', 'Salmonella infection, unspecified'),
('6669468621ea4eb1c8a0dc3e', 'A03', '0', 'Shigellosis', 'Shigellosis'),
('6669468621ea4eb1c8a0dc3f', 'A030', '1', 'Shigellosis due to Shigella dysenteriae', 'Shigellosis due to Shigella dysenteriae'),
('6669468621ea4eb1c8a0dc40', 'A031', '1', 'Shigellosis due to Shigella flexneri', 'Shigellosis due to Shigella flexneri'),
('6669468621ea4eb1c8a0dc41', 'A032', '1', 'Shigellosis due to Shigella boydii', 'Shigellosis due to Shigella boydii'),
('6669468621ea4eb1c8a0dc42', 'A033', '1', 'Shigellosis due to Shigella sonnei', 'Shigellosis due to Shigella sonnei'),
('6669468621ea4eb1c8a0dc43', 'A038', '1', 'Other shigellosis', 'Other shigellosis'),
('6669468621ea4eb1c8a0dc44', 'A039', '1', 'Shigellosis, unspecified', 'Shigellosis, unspecified'),
('6669468621ea4eb1c8a0dc45', 'A04', '0', 'Other bacterial intestinal infections', 'Other bacterial intestinal infections'),
('6669468621ea4eb1c8a0dc46', 'A040', '1', 'Enteropathogenic Escherichia coli infection', 'Enteropathogenic Escherichia coli infection'),
('6669468621ea4eb1c8a0dc47', 'A041', '1', 'Enterotoxigenic Escherichia coli infection', 'Enterotoxigenic Escherichia coli infection'),
('6669468621ea4eb1c8a0dc48', 'A042', '1', 'Enteroinvasive Escherichia coli infection', 'Enteroinvasive Escherichia coli infection'),
('6669468621ea4eb1c8a0dc49', 'A043', '1', 'Enterohemorrhagic Escherichia coli infection', 'Enterohemorrhagic Escherichia coli infection'),
('6669468621ea4eb1c8a0dc4a', 'A044', '1', 'Other intestinal Escherichia coli infections', 'Other intestinal Escherichia coli infections'),
('6669468621ea4eb1c8a0dc4b', 'A045', '1', 'Campylobacter enteritis', 'Campylobacter enteritis'),
('6669468621ea4eb1c8a0dc4c', 'A046', '1', 'Enteritis due to Yersinia enterocolitica', 'Enteritis due to Yersinia enterocolitica'),
('6669468621ea4eb1c8a0dc4d', 'A047', '0', 'Enterocolitis due to Clostridium difficile', 'Enterocolitis due to Clostridium difficile'),
('6669468621ea4eb1c8a0dc4e', 'A0471', '1', 'Enterocolitis due to Clostridium difficile, recurrent', 'Enterocolitis due to Clostridium difficile, recurrent'),
('6669468621ea4eb1c8a0dc4f', 'A0472', '1', 'Enterocolitis d/t Clostridium difficile, not spcf as recur', 'Enterocolitis due to Clostridium difficile, not specified as recurrent'),
('6669468621ea4eb1c8a0dc50', 'A048', '1', 'Other specified bacterial intestinal infections', 'Other specified bacterial intestinal infections'),
('6669468621ea4eb1c8a0dc51', 'A049', '1', 'Bacterial intestinal infection, unspecified', 'Bacterial intestinal infection, unspecified'),
('6669468621ea4eb1c8a0dc52', 'A05', '0', 'Oth bacterial foodborne intoxications, NEC', 'Other bacterial foodborne intoxications, not elsewhere classified'),
('6669468621ea4eb1c8a0dc53', 'A050', '1', 'Foodborne staphylococcal intoxication', 'Foodborne staphylococcal intoxication'),
('6669468621ea4eb1c8a0dc54', 'A051', '1', 'Botulism food poisoning', 'Botulism food poisoning'),
('6669468621ea4eb1c8a0dc55', 'A052', '1', 'Foodborne Clostridium perfringens intoxication', 'Foodborne Clostridium perfringens [Clostridium welchii] intoxication'),
('6669468621ea4eb1c8a0dc56', 'A053', '1', 'Foodborne Vibrio parahaemolyticus intoxication', 'Foodborne Vibrio parahaemolyticus intoxication'),
('6669468621ea4eb1c8a0dc57', 'A054', '1', 'Foodborne Bacillus cereus intoxication', 'Foodborne Bacillus cereus intoxication'),
('6669468621ea4eb1c8a0dc58', 'A055', '1', 'Foodborne Vibrio vulnificus intoxication', 'Foodborne Vibrio vulnificus intoxication'),
('6669468621ea4eb1c8a0dc59', 'A058', '1', 'Other specified bacterial foodborne intoxications', 'Other specified bacterial foodborne intoxications'),
('6669468621ea4eb1c8a0dc5a', 'A059', '1', 'Bacterial foodborne intoxication, unspecified', 'Bacterial foodborne intoxication, unspecified'),
('6669468621ea4eb1c8a0dc5b', 'A06', '0', 'Amebiasis', 'Amebiasis'),
('6669468621ea4eb1c8a0dc5c', 'A060', '1', 'Acute amebic dysentery', 'Acute amebic dysentery'),
('6669468621ea4eb1c8a0dc5d', 'A061', '1', 'Chronic intestinal amebiasis', 'Chronic intestinal amebiasis'),
('6669468621ea4eb1c8a0dc5e', 'A062', '1', 'Amebic nondysenteric colitis', 'Amebic nondysenteric colitis'),
('6669468621ea4eb1c8a0dc5f', 'A063', '1', 'Ameboma of intestine', 'Ameboma of intestine'),
('6669468621ea4eb1c8a0dc60', 'A064', '1', 'Amebic liver abscess', 'Amebic liver abscess'),
('6669468621ea4eb1c8a0dc61', 'A065', '1', 'Amebic lung abscess', 'Amebic lung abscess'),
('6669468621ea4eb1c8a0dc62', 'A066', '1', 'Amebic brain abscess', 'Amebic brain abscess'),
('6669468621ea4eb1c8a0dc63', 'A067', '1', 'Cutaneous amebiasis', 'Cutaneous amebiasis'),
('6669468621ea4eb1c8a0dc64', 'A068', '0', 'Amebic infection of other sites', 'Amebic infection of other sites'),
('6669468621ea4eb1c8a0dc65', 'A0681', '1', 'Amebic cystitis', 'Amebic cystitis'),
('6669468621ea4eb1c8a0dc66', 'A0682', '1', 'Other amebic genitourinary infections', 'Other amebic genitourinary infections'),
('6669468621ea4eb1c8a0dc67', 'A0689', '1', 'Other amebic infections', 'Other amebic infections'),
('6669468621ea4eb1c8a0dc68', 'A069', '1', 'Amebiasis, unspecified', 'Amebiasis, unspecified'),
('6669468621ea4eb1c8a0dc69', 'A07', '0', 'Other protozoal intestinal diseases', 'Other protozoal intestinal diseases'),
('6669468621ea4eb1c8a0dc6a', 'A070', '1', 'Balantidiasis', 'Balantidiasis'),
('6669468821ea4eb1c8a2582a', 'Z9989', '1', 'Dependence on other enabling machines and devices', 'Dependence on other enabling machines and devices');

-- --------------------------------------------------------

--
-- Table structure for table `insuranceTable`
--

CREATE TABLE `insuranceTable` (
  `id` int(11) NOT NULL,
  `insurance_name` varchar(40) DEFAULT NULL,
  `percentage` int(11) DEFAULT NULL,
  `packages` varchar(15) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `insuranceTable`
--

INSERT INTO `insuranceTable` (`id`, `insurance_name`, `percentage`, `packages`) VALUES
(0, 'NHIS', 10, '4');

-- --------------------------------------------------------

--
-- Stand-in structure for view `in_patient_list`
-- (See below for the actual view)
--
CREATE TABLE `in_patient_list` (
`sort_index` int(11)
,`bed_id` int(11)
,`allocation_id` int(11)
,`allocation_status` varchar(20)
,`allocated` timestamp
,`allocated_by` varchar(50)
,`patient_name` varchar(101)
,`patient_id` varchar(50)
,`accountNo` int(7)
,`name` varchar(100)
,`class_type` varchar(50)
,`account` varchar(10)
,`price` int(11)
,`facilityId` varchar(50)
,`status` varchar(50)
,`seen_by` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `lab`
--

CREATE TABLE `lab` (
  `test_id` int(10) NOT NULL,
  `date` datetime DEFAULT current_timestamp(),
  `patient_id` varchar(20) DEFAULT NULL,
  `test` varchar(100) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `requested_by` varchar(20) DEFAULT NULL,
  `sample` varchar(100) DEFAULT NULL,
  `result` varchar(50) DEFAULT NULL,
  `appearance` varchar(50) DEFAULT NULL,
  `microscopy` varchar(50) DEFAULT NULL,
  `culture` varchar(50) DEFAULT NULL,
  `antibiotic` varchar(50) DEFAULT NULL,
  `comment` varchar(200) DEFAULT NULL,
  `facilityId` varchar(50) DEFAULT NULL,
  `updated_at` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `lab`
--

INSERT INTO `lab` (`test_id`, `date`, `patient_id`, `test`, `status`, `requested_by`, `sample`, `result`, `appearance`, `microscopy`, `culture`, `antibiotic`, `comment`, `facilityId`, `updated_at`) VALUES
(1, '2020-01-02 00:00:00', '329-2', 'followUp', 'request', 'x-ray', 'fore-arm', 'positive', 'yeah', 'undefined', 'undefined', 'undefined', '12/12/2012', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(2, '2020-01-02 00:00:00', '329-1', 'x-ray', 'request', 'aminu', 'leg', 'hhhhjj', 'normal', 'nothing spectacular', '', 'safe', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(3, '2020-01-02 00:00:00', '329-2', 'x-ray', 'request', 'aminu', 'leg', 'jjjjjj', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(4, '2020-01-02 00:00:00', '329-2', 'x-ray', 'request', 'aminu', 'leg', 'jjjjjj', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(5, '2020-01-02 00:00:00', '329-1', 'x-ray', 'request', 'aminu', 'leg', 'hhhhjj', 'seem defect', '', 'yeah', 'nothing', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(6, '2020-01-02 00:00:00', '329-1', 'gamma', 'request', 'emaitee', 'leg', 'yyyyyy', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(7, '2020-01-02 00:00:00', '329-1', 'beta', 'request', 'teetee', 'hand', 'hhhhjj', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(8, '2020-01-02 00:00:00', '3333-1', 'red', 'request', 'uack', 'blood', 'hhhhjj', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(9, '2020-01-02 00:00:00', '3291-2', 'y-ray', 'request', 'tech', 'ggg', 'hhhhjj', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(10, '2020-01-02 00:00:00', '329-2', 'x-ray', 'request', 'aminu', 'leg', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(11, '2020-01-02 00:00:00', '3608-1', 'htf', 'request', 'aminu', 'rese', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(12, '2020-01-02 00:00:00', '329-2', 'urine test', 'request', 'aminu', 'urine', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(13, '2020-01-02 00:00:00', '329-2', 'blood test', 'request', 'aminu', 'blood', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(14, '2020-01-02 00:00:00', '329-2', 'urine test', 'request', 'aminu', 'urine', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(15, '2020-01-02 00:00:00', '3233-1', 'blood test', 'request', 'aminu', 'blood', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(16, '2020-01-02 00:00:00', '329-2', 'blood test', 'request', 'aminu', 'blood', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(17, '2020-01-02 00:00:00', '329-2', 'x-ray', 'request', 'aminu', 'leg', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(18, '2020-01-02 00:00:00', '329-1', 'urine test', 'request', 'aminu', 'urine', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(19, '2020-01-02 00:00:00', '329-2', 'urea test', 'request', 'aminu', 'urine', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(20, '2020-01-02 00:00:00', '3608-1', 'urea', 'request', 'Aisha', 'urine', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(21, '2020-01-02 00:00:00', '329-2', 'x-ray', 'request', 'Aisha', 'arm', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(22, '2020-01-02 00:00:00', '3608-1', 'urea', 'request', 'Aisha', 'urine', '', '', '', '', '', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(23, '2020-01-06 17:24:08', '329-2', 'test', 'request', 'doctor', 'test sample', NULL, NULL, NULL, NULL, NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(24, '2020-01-06 19:16:11', '3608-1', 'testing microphone', 'request', 'doctor', 'yea yeah', NULL, NULL, NULL, NULL, NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(25, '2020-01-06 19:24:56', '3608-1', 'yaya yepa', 'request', 'doctor', 'another', NULL, NULL, NULL, NULL, NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(26, '2020-01-07 07:36:45', '3575-1', 'afsd', 'request', 'doctor', 'asdf', NULL, NULL, NULL, NULL, NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(27, '2020-01-13 15:17:15', '3588-1', 'pcv', 'request', 'abdurrahman', 'blood', NULL, NULL, NULL, NULL, NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(28, '2020-01-13 15:17:15', '3588-1', 'u/e/cr', 'request', 'abdurrahman', 'blood', NULL, NULL, NULL, NULL, NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(29, '2020-02-22 11:47:34', '3584-1', 'L;K\'L', 'request', 'doctor', ';L[\\', NULL, NULL, NULL, NULL, NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(30, '2020-03-14 14:31:31', '3742-1', 'fbc', 'request', 'abdurrahman', 'blood', NULL, NULL, NULL, NULL, NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL),
(31, '2020-03-14 14:31:31', '3742-1', 'uecr', 'request', 'abdurrahman', 'blood', NULL, NULL, NULL, NULL, NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `labservices`
--

CREATE TABLE `labservices` (
  `labhead` varchar(50) DEFAULT NULL,
  `labsubhead` varchar(50) DEFAULT NULL,
  `test` varchar(50) DEFAULT NULL,
  `unit` varchar(50) DEFAULT NULL,
  `value` varchar(50) DEFAULT NULL,
  `test_range` varchar(50) DEFAULT NULL,
  `id` int(20) NOT NULL,
  `facilityId` varchar(50) NOT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `labservices`
--

INSERT INTO `labservices` (`labhead`, `labsubhead`, `test`, `unit`, `value`, `test_range`, `id`, `facilityId`, `createdAt`) VALUES
('max', 'add', NULL, 'blue', 'dnffj', '12333', 1, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-01-23 05:21:27'),
('maxss', 'add', 'dnffj', 'blue', NULL, '12333', 2, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-01-23 05:21:27'),
('max', 'add', 'dnffj', 'blue', NULL, '12333', 3, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-01-23 05:21:27'),
('max', 'add', 'dnffj', 'blue', NULL, '12333', 4, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-01-23 05:21:27'),
('max', 'add', 'dnffj', 'blue', NULL, '12333', 5, '22', '2020-01-23 12:39:37'),
('ssssddddd', 'weeew', 'uby', 'sd', NULL, '324567', 6, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-01-23 13:07:42'),
('prime', 'prime lab', 'emathology', 'mm/g', NULL, '12-20', 7, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-01-23 13:13:33'),
('ssssddddd', 'weeew', 'uby', 'eee', NULL, '324567', 8, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-01-23 14:15:06'),
('ssssddddd', 'weeew', 'uby', 'sd', NULL, '324567', 9, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-01-23 14:38:04'),
('ssssddddd', 'weeew', 'wertyu', 'eee', NULL, '324567', 10, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-17 10:49:14'),
('ssssddddd', 'weeew', 'uby', 'hjdskjsdjjkds', NULL, '12-20', 11, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-17 11:15:56'),
('prime', 'prime_lab', 'urine_test', '34', NULL, '324567', 12, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-17 17:22:49'),
('prime', 'prime_lab', 'urine_test', '34', NULL, '324567', 13, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-17 17:23:35'),
('ssssddddd', 'ghhjskjdjkd', '', 'sd', NULL, '', 14, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-19 15:43:16'),
('ssssddddd', 'ghhjskjdjkd', '', 'sd', NULL, '', 15, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-19 15:43:38'),
('ssssddddd', 'ghhjskjdjkd', '', 'sd', NULL, '', 16, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-19 15:44:53'),
('ssssddddd', 'ghhjskjdjkd', 'uby', 'sd', NULL, '324567', 17, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-19 15:45:04'),
('fahad', 'ado', 'urine', 'sd', NULL, '12-20', 18, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-26 15:45:07');

-- --------------------------------------------------------

--
-- Table structure for table `lab_codes`
--

CREATE TABLE `lab_codes` (
  `lab_code_number` int(10) NOT NULL,
  `code_initial` int(5) NOT NULL,
  `lab_year` int(5) NOT NULL,
  `lab_id` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `lab_codes`
--

INSERT INTO `lab_codes` (`lab_code_number`, `code_initial`, `lab_year`, `lab_id`) VALUES
(2000, 2, 21, 0),
(3000, 3, 21, 0),
(4000, 4, 21, 0),
(5000, 5, 21, 0);

-- --------------------------------------------------------

--
-- Stand-in structure for view `lab_info`
-- (See below for the actual view)
--
CREATE TABLE `lab_info` (
`sort_index` int(11)
,`sn` int(11)
,`created_at` timestamp
,`facilityId` varchar(50)
,`id` int(100)
,`code` varchar(50)
,`booking_no` varchar(100)
,`request_id` varchar(50)
,`patient_id` varchar(50)
,`name` varchar(101)
,`DOB` varchar(20)
,`Gender` varchar(10)
,`qms_dept_id` int(11)
,`head` varchar(100)
,`subhead` varchar(100)
,`unit` varchar(100)
,`range_from` varchar(100)
,`range_to` varchar(100)
,`price` int(100)
,`old_price` int(100)
,`modeOfPayment` varchar(30)
,`account` varchar(50)
,`account_name` varchar(100)
,`payable_head` varchar(50)
,`payable_head_name` varchar(50)
,`receivable_head` varchar(50)
,`receivable_head_name` varchar(50)
,`commission_type` varchar(50)
,`percentage` int(11)
,`description` varchar(200)
,`test` varchar(100)
,`test_group` varchar(50)
,`specimen` varchar(100)
,`noOfLabels` int(11)
,`label_type` varchar(20)
,`label_name` varchar(100)
,`department` varchar(50)
,`unit_name` varchar(50)
,`unit_code` varchar(50)
,`result` varchar(200)
,`h_value` varchar(20)
,`o_value` varchar(20)
,`appearance` varchar(200)
,`serology` varchar(200)
,`culture_yielded` varchar(100)
,`sensitivity` varchar(200)
,`resistivity` varchar(200)
,`intermediaryTo` varchar(200)
,`lab_code` int(11)
,`selectable` varchar(20)
,`status` varchar(20)
,`print_type` varchar(20)
,`report_type` varchar(20)
,`collect_sample` varchar(20)
,`to_be_reported` varchar(20)
,`to_be_analyzed` varchar(20)
,`created_by` varchar(50)
,`sample_collected_by` varchar(50)
,`sample_collected_at` datetime
,`analyzed_by` varchar(50)
,`analyzed_at` datetime
,`result_by` varchar(50)
,`result_at` datetime
,`reviewed_by` varchar(50)
,`reviewed_at` datetime
,`printed_by` varchar(50)
,`printed_at` datetime
,`n_unit` varchar(20)
,`n_range_from` varchar(20)
,`n_range_to` varchar(20)
,`receiptNo` varchar(50)
,`sop_instance_id` varchar(200)
,`uploaded_at` timestamp
,`uploaded_by` varchar(100)
,`payment_status` varchar(20)
,`approval_status` varchar(50)
,`report_fee_status` varchar(20)
,`department_head` varchar(30)
,`group_head` varchar(20)
,`patient_status` varchar(20)
,`printable` tinyint(1)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `lab_info_2`
-- (See below for the actual view)
--
CREATE TABLE `lab_info_2` (
`sn` int(11)
,`created_at` timestamp
,`facilityId` varchar(50)
,`id` int(100)
,`code` varchar(50)
,`booking_no` varchar(100)
,`request_id` varchar(50)
,`patient_id` varchar(50)
,`name` varchar(101)
,`DOB` varchar(20)
,`Gender` varchar(10)
,`qms_dept_id` int(11)
,`head` varchar(100)
,`subhead` varchar(100)
,`unit` varchar(100)
,`range_from` varchar(100)
,`range_to` varchar(100)
,`price` int(100)
,`old_price` int(100)
,`modeOfPayment` varchar(30)
,`account` varchar(50)
,`account_name` varchar(100)
,`payable_head` varchar(50)
,`payable_head_name` varchar(50)
,`receivable_head` varchar(50)
,`receivable_head_name` varchar(50)
,`commission_type` varchar(50)
,`percentage` int(11)
,`description` varchar(200)
,`test` varchar(100)
,`test_group` varchar(50)
,`specimen` varchar(100)
,`noOfLabels` int(11)
,`label_type` varchar(20)
,`label_name` varchar(100)
,`department` varchar(50)
,`unit_name` varchar(50)
,`unit_code` varchar(50)
,`result` varchar(200)
,`h_value` varchar(20)
,`o_value` varchar(20)
,`appearance` varchar(200)
,`serology` varchar(200)
,`culture_yielded` varchar(100)
,`sensitivity` varchar(200)
,`resistivity` varchar(200)
,`intermediaryTo` varchar(200)
,`lab_code` int(11)
,`selectable` varchar(20)
,`status` varchar(20)
,`print_type` varchar(20)
,`report_type` varchar(20)
,`collect_sample` varchar(20)
,`to_be_reported` varchar(20)
,`to_be_analyzed` varchar(20)
,`created_by` varchar(50)
,`sample_collected_by` varchar(50)
,`sample_collected_at` datetime
,`analyzed_by` varchar(50)
,`analyzed_at` datetime
,`result_by` varchar(50)
,`result_at` datetime
,`reviewed_by` varchar(50)
,`reviewed_at` datetime
,`printed_by` varchar(50)
,`printed_at` datetime
,`n_unit` varchar(20)
,`n_range_from` varchar(20)
,`n_range_to` varchar(20)
,`receiptNo` varchar(50)
,`sop_instance_id` varchar(200)
,`uploaded_at` timestamp
,`uploaded_by` varchar(100)
,`payment_status` varchar(20)
,`approval_status` varchar(50)
,`report_fee_status` varchar(20)
,`department_head` varchar(30)
,`group_head` varchar(20)
,`patient_status` varchar(20)
);

-- --------------------------------------------------------

--
-- Table structure for table `lab_inventory_table`
--

CREATE TABLE `lab_inventory_table` (
  `id` int(11) NOT NULL,
  `batch_code` varchar(50) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `supplier` varchar(100) NOT NULL,
  `price` varchar(100) NOT NULL,
  `quantity` varchar(100) NOT NULL,
  `invoice_no` varchar(100) NOT NULL,
  `re_order_level` varchar(100) NOT NULL,
  `facilityId` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `lab_inventory_table`
--

INSERT INTO `lab_inventory_table` (`id`, `batch_code`, `item_name`, `supplier`, `price`, `quantity`, `invoice_no`, `re_order_level`, `facilityId`, `created_at`, `created_by`) VALUES
(1, '1', 'Reagent', 'undefined', '100', '20', '', '10', '966a89f6-05d8-4564-b319-2f8863821e75', '2020-10-09 10:18:16', 'admin');

-- --------------------------------------------------------

--
-- Table structure for table `lab_numbers`
--

CREATE TABLE `lab_numbers` (
  `id` int(11) NOT NULL,
  `patient_acc_no` int(11) NOT NULL,
  `patient_id` varchar(50) NOT NULL,
  `lab_no` varchar(50) NOT NULL,
  `history` varchar(2000) DEFAULT NULL,
  `status` varchar(200) DEFAULT NULL,
  `facilityId` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `lab_process`
-- (See below for the actual view)
--
CREATE TABLE `lab_process` (
`sn` int(11)
,`created_at` timestamp
,`facilityId` varchar(50)
,`id` int(100)
,`qms_dept_id` int(11)
,`code` varchar(50)
,`booking_no` varchar(100)
,`request_id` varchar(50)
,`patient_id` varchar(50)
,`name` varchar(101)
,`DOB` varchar(20)
,`Gender` varchar(10)
,`head` varchar(100)
,`subhead` varchar(100)
,`unit` varchar(100)
,`range_from` varchar(100)
,`range_to` varchar(100)
,`price` int(100)
,`old_price` int(100)
,`commission_type` varchar(50)
,`percentage` int(11)
,`description` varchar(200)
,`specimen` varchar(100)
,`noOfLabels` int(11)
,`label_type` varchar(20)
,`label_name` varchar(100)
,`group_head` varchar(200)
,`department` varchar(50)
,`department_head` varchar(200)
,`result` varchar(200)
,`h_value` varchar(20)
,`o_value` varchar(20)
,`appearance` varchar(200)
,`serology` varchar(200)
,`culture_yielded` varchar(100)
,`sensitivity` varchar(200)
,`resistivity` varchar(200)
,`intermediaryTo` varchar(200)
,`lab_code` int(11)
,`selectable` varchar(20)
,`status` varchar(20)
,`unit_code` varchar(50)
,`unit_name` varchar(50)
,`print_type` varchar(20)
,`report_type` varchar(20)
,`collect_sample` varchar(20)
,`to_be_reported` varchar(20)
,`to_be_analyzed` varchar(20)
,`created_by` varchar(50)
,`sample_collected_by` varchar(50)
,`sample_collected_at` datetime
,`analyzed_by` varchar(50)
,`analyzed_at` datetime
,`result_by` varchar(50)
,`result_at` datetime
,`reviewed_by` varchar(50)
,`reviewed_at` datetime
,`printed_by` varchar(50)
,`printed_at` datetime
,`n_unit` varchar(20)
,`n_range_from` varchar(20)
,`n_range_to` varchar(20)
,`receiptNo` varchar(50)
,`sop_instance_id` varchar(200)
,`uploaded_at` timestamp
,`uploaded_by` varchar(100)
,`payment_status` varchar(20)
,`approval_status` varchar(50)
,`patient_status` varchar(20)
,`test` varchar(100)
,`test_group` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `lab_process_selected`
--

CREATE TABLE `lab_process_selected` (
  `id` int(100) NOT NULL DEFAULT 0,
  `subhead` varchar(100) NOT NULL,
  `head` varchar(100) NOT NULL,
  `department_head` varchar(200) NOT NULL,
  `group_head` varchar(200) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `lab_request2`
-- (See below for the actual view)
--
CREATE TABLE `lab_request2` (
`sn` int(11)
,`created_at` timestamp
,`facilityId` varchar(50)
,`id` int(100)
,`qms_dept_id` int(11)
,`code` varchar(50)
,`name` varchar(101)
,`DOB` varchar(20)
,`Gender` varchar(10)
,`booking_no` varchar(100)
,`request_id` varchar(50)
,`patient_id` varchar(50)
,`head` varchar(100)
,`subhead` varchar(100)
,`unit` varchar(100)
,`range_from` varchar(100)
,`range_to` varchar(100)
,`price` int(100)
,`old_price` int(100)
,`commission_type` varchar(50)
,`percentage` int(11)
,`description` varchar(200)
,`specimen` varchar(100)
,`noOfLabels` int(11)
,`label_type` varchar(20)
,`label_name` varchar(100)
,`group_head` varchar(200)
,`department` varchar(50)
,`unit_code` varchar(50)
,`unit_name` varchar(50)
,`result` varchar(200)
,`h_value` varchar(20)
,`o_value` varchar(20)
,`appearance` varchar(200)
,`serology` varchar(200)
,`culture_yielded` varchar(100)
,`sensitivity` varchar(200)
,`resistivity` varchar(200)
,`intermediaryTo` varchar(200)
,`lab_code` int(11)
,`selectable` varchar(20)
,`status` varchar(20)
,`print_type` varchar(20)
,`report_type` varchar(20)
,`collect_sample` varchar(20)
,`to_be_reported` varchar(20)
,`to_be_analyzed` varchar(20)
,`created_by` varchar(50)
,`sample_collected_by` varchar(50)
,`sample_collected_at` datetime
,`analyzed_by` varchar(50)
,`analyzed_at` datetime
,`result_by` varchar(50)
,`result_at` datetime
,`reviewed_by` varchar(50)
,`reviewed_at` datetime
,`printed_by` varchar(50)
,`printed_at` datetime
,`n_unit` varchar(20)
,`n_range_from` varchar(20)
,`n_range_to` varchar(20)
,`receiptNo` varchar(50)
,`sop_instance_id` varchar(200)
,`uploaded_at` timestamp
,`uploaded_by` varchar(100)
,`payment_status` varchar(20)
,`approval_status` varchar(50)
,`patient_status` varchar(20)
,`test` varchar(100)
,`test_group` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `lab_requests`
-- (See below for the actual view)
--
CREATE TABLE `lab_requests` (
`department` varchar(50)
,`patient_id` varchar(50)
,`status` varchar(200)
);

-- --------------------------------------------------------

--
-- Table structure for table `lab_requisition`
--

CREATE TABLE `lab_requisition` (
  `facilityId` varchar(50) NOT NULL,
  `id` int(100) NOT NULL,
  `code` varchar(50) DEFAULT NULL,
  `booking_no` varchar(100) DEFAULT NULL,
  `token` varchar(64) DEFAULT NULL,
  `request_id` varchar(50) DEFAULT NULL,
  `patient_id` varchar(50) DEFAULT NULL,
  `test` varchar(100) DEFAULT NULL,
  `description` varchar(100) NOT NULL,
  `price` int(11) DEFAULT NULL,
  `old_price` int(11) DEFAULT NULL,
  `percentage` int(11) DEFAULT NULL,
  `result` varchar(200) DEFAULT NULL,
  `h_value` varchar(20) DEFAULT NULL,
  `o_value` varchar(20) DEFAULT NULL,
  `appearance` varchar(200) DEFAULT NULL,
  `serology` varchar(200) DEFAULT NULL,
  `culture_yielded` varchar(100) DEFAULT NULL,
  `sensitivity` varchar(200) DEFAULT NULL,
  `resistivity` varchar(200) DEFAULT NULL,
  `intermediaryTo` varchar(200) DEFAULT NULL,
  `department` varchar(50) DEFAULT NULL,
  `test_group` varchar(50) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` varchar(100) DEFAULT NULL,
  `created_by` varchar(50) DEFAULT NULL,
  `sample_collected_by` varchar(50) DEFAULT NULL,
  `sample_collected_at` datetime DEFAULT NULL,
  `analyzed_by` varchar(50) DEFAULT NULL,
  `analyzed_at` datetime DEFAULT NULL,
  `result_by` varchar(50) DEFAULT NULL,
  `result_at` datetime DEFAULT NULL,
  `sop_instance_id` varchar(200) DEFAULT NULL,
  `uploaded_at` timestamp NULL DEFAULT NULL,
  `uploaded_by` varchar(100) DEFAULT NULL,
  `reviewed_by` varchar(50) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `printed_by` varchar(50) DEFAULT NULL,
  `printed_at` datetime DEFAULT NULL,
  `unit` varchar(20) DEFAULT NULL,
  `range_from` varchar(20) DEFAULT NULL,
  `range_to` varchar(20) DEFAULT NULL,
  `receiptNo` varchar(50) DEFAULT NULL,
  `payment_status` varchar(20) NOT NULL,
  `label_type` varchar(20) NOT NULL,
  `noOfLabels` int(11) NOT NULL,
  `print_type` varchar(20) NOT NULL,
  `approval_status` varchar(50) NOT NULL DEFAULT 'pending',
  `dept_code` varchar(11) DEFAULT NULL,
  `requested_by` varchar(50) DEFAULT NULL,
  `patient_status` varchar(20) DEFAULT NULL,
  `account_name` varchar(50) NOT NULL,
  `unit_code` varchar(50) NOT NULL,
  `unit_name` varchar(50) NOT NULL,
  `payable_head` varchar(50) NOT NULL,
  `receivable_head` varchar(50) NOT NULL,
  `account` varchar(50) DEFAULT NULL,
  `department_code` varchar(50) NOT NULL,
  `patient_name` varchar(50) NOT NULL,
  `modeOfPayment` varchar(30) DEFAULT NULL,
  `report_fee_status` varchar(20) DEFAULT NULL,
  `department_head` varchar(30) DEFAULT NULL,
  `group_head` varchar(20) DEFAULT NULL,
  `client_type` varchar(20) DEFAULT NULL,
  `client_account` varchar(20) DEFAULT NULL,
  `discount` varchar(11) DEFAULT NULL,
  `discount_head` varchar(20) NOT NULL,
  `discount_head_name` varchar(50) NOT NULL,
  `discount_amount` varchar(11) DEFAULT NULL,
  `doctor_fullname` varchar(80) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `lab_requisition`
--

INSERT INTO `lab_requisition` (`facilityId`, `id`, `code`, `booking_no`, `token`, `request_id`, `patient_id`, `test`, `description`, `price`, `old_price`, `percentage`, `result`, `h_value`, `o_value`, `appearance`, `serology`, `culture_yielded`, `sensitivity`, `resistivity`, `intermediaryTo`, `department`, `test_group`, `status`, `created_at`, `updated_at`, `created_by`, `sample_collected_by`, `sample_collected_at`, `analyzed_by`, `analyzed_at`, `result_by`, `result_at`, `sop_instance_id`, `uploaded_at`, `uploaded_by`, `reviewed_by`, `reviewed_at`, `printed_by`, `printed_at`, `unit`, `range_from`, `range_to`, `receiptNo`, `payment_status`, `label_type`, `noOfLabels`, `print_type`, `approval_status`, `dept_code`, `requested_by`, `patient_status`, `account_name`, `unit_code`, `unit_name`, `payable_head`, `receivable_head`, `account`, `department_code`, `patient_name`, `modeOfPayment`, `report_fee_status`, `department_head`, `group_head`, `client_type`, `client_account`, `discount`, `discount_head`, `discount_head_name`, `discount_amount`, `doctor_fullname`) VALUES
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 1, NULL, NULL, NULL, '251030112037', '35-1', '2000', 'Hematology', 9000, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '0', 'ordered', '2025-10-30 10:27:58', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'In-Patient', '', '', '', '', '', '20001', '', 'Aminu Mustapha', NULL, NULL, NULL, NULL, '', '35', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 2, '221199932', '21266749', NULL, '251030122358', '23-1', '2001', 'PCV', 1000, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '0', 'ordered', '2025-10-30 11:25:08', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Mustapha Bakura', NULL, NULL, NULL, NULL, '', '23', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 3, '221199931', '21266748', NULL, '251030122523', '24-1', '2000', 'Hematology', 9000, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '0', 'ordered', '2025-10-30 11:25:32', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Kate Kate', NULL, NULL, NULL, NULL, '', '24', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 4, '221199936', '21266753', NULL, '251030122909', '31-1', '2003', 'Prothrombin time', 2500, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '0', 'ordered', '2025-10-30 11:29:27', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Today Today', NULL, NULL, NULL, NULL, '', '31', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 5, '221199936', '21266753', NULL, '251030122909', '31-1', '20031', 'Control(PT)', 0, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '0', 'ordered', '2025-10-30 11:29:27', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Today Today', NULL, NULL, NULL, NULL, '', '31', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 6, '221199936', '21266753', NULL, '251030122909', '31-1', '20032', 'Sample(PT)', 0, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '0', 'ordered', '2025-10-30 11:29:27', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Today Today', NULL, NULL, NULL, NULL, '', '31', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 7, '221199936', '21266753', NULL, '251030122909', '31-1', '20033', 'INR(PT)', 0, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '0', 'ordered', '2025-10-30 11:29:27', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Today Today', NULL, NULL, NULL, NULL, '', '31', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 8, NULL, NULL, NULL, '251112011809', '21-1', '30010280', 'CONPRHENSIVE GPR ESTIMATION', 20000, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '3000', '0', 'ordered', '2025-11-12 12:18:09', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'single', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20002', '', 'Amina Amina', NULL, NULL, NULL, NULL, '', '', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 9, NULL, NULL, NULL, '251112011809', '21-1', '2000193', 'INR (PT)', 1500, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '0', 'ordered', '2025-11-12 12:18:09', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Amina Amina', NULL, NULL, NULL, NULL, '', '', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 10, NULL, NULL, NULL, '251112011928', '19-1', '30010280', 'CONPRHENSIVE GPR ESTIMATION', 20000, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '3000', '0', 'ordered', '2025-11-12 12:19:28', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'single', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20002', '', 'Haruna Donald', NULL, NULL, NULL, NULL, '', '', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 11, NULL, NULL, NULL, '251112011928', '19-1', '10001', 'Genotype', 4500, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1000', '0', 'ordered', '2025-11-12 12:19:28', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Haruna Donald', NULL, NULL, NULL, NULL, '', '', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 12, NULL, '21266758', NULL, '251112012508', '20-1', '10001', 'Genotype', 4500, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1000', '0', 'ordered', '2025-11-12 12:25:08', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Kalthum Zubairu', NULL, NULL, NULL, NULL, '', '', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 13, '221199944', '21266761', NULL, '251112012508', '20-1', '2000193', 'INR (PT)', 1500, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '200019', 'ordered', '2025-11-12 12:25:08', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Kalthum Zubairu', NULL, NULL, NULL, NULL, '', '', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 14, '221199944', '21266761', NULL, '251112012508', '20-1', '2000192', 'Sample (PT)', 2000, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '200019', 'ordered', '2025-11-12 12:25:08', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Kalthum Zubairu', NULL, NULL, NULL, NULL, '', '', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 15, '221199944', '21266761', NULL, '251112012508', '20-1', '200019', 'INR', 3000, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', '200019', 'ordered', '2025-11-12 12:25:08', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'Out-Patient', '', '', '', '', '', '20001', '', 'Kalthum Zubairu', NULL, NULL, NULL, NULL, '', '', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 16, NULL, '21266764', NULL, '251112012758', '35-1', '10001', 'Genotype', 4500, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1000', '0', 'ordered', '2025-11-12 12:28:20', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'grouped', 1, 'grouped', '', NULL, 'abdurrahman', 'In-Patient', '', '', '', '', '', '20001', '', 'Aminu Mustapha', NULL, NULL, NULL, NULL, '', '35', '', '', '', '', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 17, '32154990', '21266765', NULL, '251112012758', '35-1', '30010280', 'CONPRHENSIVE GPR ESTIMATION', 20000, NULL, 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '3000', '0', 'ordered', '2025-11-12 12:28:20', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', 'single', 1, 'grouped', '', NULL, 'abdurrahman', 'In-Patient', '', '', '', '', '', '20002', '', 'Aminu Mustapha', NULL, NULL, NULL, NULL, '', '35', '', '', '', '', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `lab_requisition_no_pid`
--

CREATE TABLE `lab_requisition_no_pid` (
  `facilityId` varchar(50) DEFAULT NULL,
  `id` int(100) NOT NULL DEFAULT 0,
  `code` varchar(50) DEFAULT NULL,
  `booking_no` varchar(100) DEFAULT NULL,
  `token` varchar(64) DEFAULT NULL,
  `request_id` varchar(50) DEFAULT NULL,
  `patient_id` varchar(50) DEFAULT NULL,
  `test` varchar(100) DEFAULT NULL,
  `description` varchar(100) NOT NULL,
  `price` int(11) DEFAULT NULL,
  `old_price` int(11) DEFAULT NULL,
  `percentage` int(11) DEFAULT NULL,
  `result` varchar(200) DEFAULT NULL,
  `h_value` varchar(20) DEFAULT NULL,
  `o_value` varchar(20) DEFAULT NULL,
  `appearance` varchar(200) DEFAULT NULL,
  `serology` varchar(200) DEFAULT NULL,
  `culture_yielded` varchar(100) DEFAULT NULL,
  `sensitivity` varchar(200) DEFAULT NULL,
  `resistivity` varchar(200) DEFAULT NULL,
  `intermediaryTo` varchar(200) DEFAULT NULL,
  `department` varchar(50) DEFAULT NULL,
  `test_group` varchar(50) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` varchar(100) DEFAULT NULL,
  `created_by` varchar(50) DEFAULT NULL,
  `sample_collected_by` varchar(50) DEFAULT NULL,
  `sample_collected_at` datetime DEFAULT NULL,
  `analyzed_by` varchar(50) DEFAULT NULL,
  `analyzed_at` datetime DEFAULT NULL,
  `result_by` varchar(50) DEFAULT NULL,
  `result_at` datetime DEFAULT NULL,
  `sop_instance_id` varchar(200) DEFAULT NULL,
  `uploaded_at` timestamp NULL DEFAULT NULL,
  `uploaded_by` varchar(100) DEFAULT NULL,
  `reviewed_by` varchar(50) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `printed_by` varchar(50) DEFAULT NULL,
  `printed_at` datetime DEFAULT NULL,
  `unit` varchar(20) DEFAULT NULL,
  `range_from` varchar(20) DEFAULT NULL,
  `range_to` varchar(20) DEFAULT NULL,
  `receiptNo` varchar(50) DEFAULT NULL,
  `payment_status` varchar(20) NOT NULL,
  `label_type` varchar(20) NOT NULL,
  `noOfLabels` int(11) NOT NULL,
  `print_type` varchar(20) NOT NULL,
  `approval_status` varchar(50) NOT NULL DEFAULT 'pending',
  `dept_code` varchar(11) DEFAULT NULL,
  `requested_by` varchar(50) DEFAULT NULL,
  `patient_status` varchar(20) DEFAULT NULL,
  `account_name` varchar(50) NOT NULL,
  `unit_code` varchar(50) NOT NULL,
  `unit_name` varchar(50) NOT NULL,
  `payable_head` varchar(50) NOT NULL,
  `receivable_head` varchar(50) NOT NULL,
  `account` varchar(50) NOT NULL,
  `department_code` varchar(50) NOT NULL,
  `patient_name` varchar(50) NOT NULL,
  `modeOfPayment` varchar(30) DEFAULT NULL,
  `report_fee_status` varchar(20) DEFAULT NULL,
  `department_head` varchar(30) DEFAULT NULL,
  `group_head` varchar(20) DEFAULT NULL,
  `client_type` varchar(20) DEFAULT NULL,
  `client_account` varchar(20) DEFAULT NULL,
  `discount` varchar(11) DEFAULT NULL,
  `discount_head` varchar(20) NOT NULL,
  `discount_head_name` varchar(50) NOT NULL,
  `discount_amount` varchar(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lab_requisition_sub`
--

CREATE TABLE `lab_requisition_sub` (
  `sn` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `id` int(100) NOT NULL DEFAULT 0,
  `qms_dept_id` int(11) NOT NULL,
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `booking_no` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `request_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `patient_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `name` varchar(101) DEFAULT NULL,
  `DOB` varchar(20) DEFAULT NULL,
  `Gender` varchar(10) DEFAULT NULL,
  `head` varchar(100) NOT NULL,
  `subhead` varchar(100) NOT NULL,
  `unit` varchar(100) DEFAULT NULL,
  `range_from` varchar(100) DEFAULT NULL,
  `range_to` varchar(100) DEFAULT NULL,
  `price` int(100) NOT NULL,
  `old_price` int(100) NOT NULL,
  `commission_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `percentage` int(11) NOT NULL,
  `description` varchar(200) NOT NULL,
  `specimen` varchar(100) NOT NULL,
  `noOfLabels` int(11) NOT NULL,
  `label_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `label_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `group_head` varchar(200) NOT NULL,
  `department` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `department_head` varchar(200) NOT NULL,
  `result` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `h_value` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `o_value` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `appearance` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `serology` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `culture_yielded` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `sensitivity` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `resistivity` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `intermediaryTo` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `lab_code` int(11) NOT NULL,
  `selectable` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `unit_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `unit_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `print_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `report_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `collect_sample` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `to_be_reported` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `to_be_analyzed` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `sample_collected_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `sample_collected_at` datetime DEFAULT NULL,
  `analyzed_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `analyzed_at` datetime DEFAULT NULL,
  `result_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `result_at` datetime DEFAULT NULL,
  `reviewed_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `printed_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `printed_at` datetime DEFAULT NULL,
  `n_unit` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `n_range_from` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `n_range_to` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `receiptNo` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `sop_instance_id` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `uploaded_at` timestamp NULL DEFAULT NULL,
  `uploaded_by` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `payment_status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `approval_status` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
  `patient_status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `test` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `test_group` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lab_setup`
--

CREATE TABLE `lab_setup` (
  `id` binary(0) DEFAULT NULL,
  `subhead` varchar(100) NOT NULL,
  `qms_dept_id` int(11) NOT NULL,
  `description` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `price` int(100) NOT NULL,
  `old_price` int(100) NOT NULL,
  `sort_index` int(11) NOT NULL,
  `account` varchar(50) DEFAULT NULL,
  `head` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `unit` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `range_from` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `range_to` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `other_range` varchar(50) CHARACTER SET utf8 COLLATE utf8_swedish_ci DEFAULT NULL,
  `specimen` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `commission_type` varchar(50) NOT NULL,
  `percentage` int(11) NOT NULL,
  `noOfLabels` int(11) NOT NULL,
  `label_type` varchar(20) DEFAULT NULL,
  `report_type` varchar(20) DEFAULT NULL,
  `print_type` varchar(20) DEFAULT NULL,
  `collect_sample` varchar(20) DEFAULT NULL,
  `to_be_analyzed` varchar(20) DEFAULT NULL,
  `to_be_reported` varchar(20) DEFAULT NULL,
  `upload_doc` varchar(20) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` varchar(100) DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `created_by` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `lab_head` int(10) NOT NULL,
  `lab_code` int(11) NOT NULL,
  `selectable` varchar(20) NOT NULL,
  `label_name` varchar(100) NOT NULL,
  `unit_code` varchar(50) NOT NULL,
  `unit_name` varchar(50) NOT NULL,
  `payable_head` varchar(50) NOT NULL,
  `receivable_head` varchar(50) NOT NULL,
  `account_name` varchar(100) NOT NULL,
  `payable_head_name` varchar(50) NOT NULL,
  `receivable_head_name` varchar(50) NOT NULL,
  `department_code` varchar(50) NOT NULL,
  `printable` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `lab_setup`
--

INSERT INTO `lab_setup` (`id`, `subhead`, `qms_dept_id`, `description`, `price`, `old_price`, `sort_index`, `account`, `head`, `unit`, `range_from`, `range_to`, `other_range`, `specimen`, `commission_type`, `percentage`, `noOfLabels`, `label_type`, `report_type`, `print_type`, `collect_sample`, `to_be_analyzed`, `to_be_reported`, `upload_doc`, `created_at`, `updated_at`, `facilityId`, `created_by`, `lab_head`, `lab_code`, `selectable`, `label_name`, `unit_code`, `unit_name`, `payable_head`, `receivable_head`, `account_name`, `payable_head_name`, `receivable_head_name`, `department_code`, `printable`) VALUES
(NULL, '1000', 0, 'PSC Specialist Clinic', 0, 0, 0, NULL, '', NULL, NULL, NULL, '', '', '', 0, 1, 'single', NULL, 'grouped', 'no', 'yes', NULL, NULL, '2021-05-20 06:10:29', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 0, 0, 'not allowed', 'PSC Specialist Clinic', '', '', '', '', '', '', '', '', 0),
(NULL, '10001', 0, 'Genotype', 4500, 4000, 0, '20001', '2022', '', '', '', NULL, '', '', 0, 1, 'grouped', 'input', 'grouped', 'no', 'yes', 'no', 'no', '2021-12-02 05:17:21', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 0, 0, '', 'Genotype', '', '', '', '', '', '', '', '', 1),
(NULL, '2000', 3, 'Hematology', 9000, 5000, 0, '20001', '2022', '', '', '', '', 'No specimen', '', 0, 1, 'grouped', NULL, 'grouped', 'no', 'yes', NULL, NULL, '2021-05-20 06:10:29', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 2000, 0, 'not allowed', 'Hematology', '', '', '', '', '', '', '', '', 1),
(NULL, '4042', 3, 'WIDAL TEST Ab.', 800, 800, 0, '20003', '2022', '', '', '', '', 'Blood', 'percentage', 15, 1, 'grouped', 'input', 'grouped', 'no', 'yes', 'yes', NULL, '2021-05-22 06:54:49', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 0, 4000, '', 'WIDAL TEST Ab.', '', '', '', '', '', '', '', '', 0),
('', '40422', 3, 'S. Paratyphi A (O, H)', 0, 0, 2, NULL, '4042', '', '', '', NULL, 'Blood', 'percentage', 15, 1, 'grouped', 'ho_widal', 'grouped', 'no', 'yes', 'yes', NULL, '2021-05-20 06:10:29', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'admin', 0, 4000, 'not allowed', 'WIDAL TEST Ab.', '', '', '', '', '', '', '', '', 1),
('', '40423', 3, 'S. Paratyphi B (O, H)', 0, 0, 3, NULL, '4042', '', '', '', NULL, 'Blood', 'percentage', 15, 1, 'grouped', 'ho_widal', 'grouped', 'no', 'yes', 'yes', NULL, '2021-05-20 06:10:29', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'admin', 0, 4000, 'not allowed', 'WIDAL TEST Ab.', '', '', '', '', '', '', '', '', 1),
('', '40424', 3, 'S. Typhi (O, H)', 0, 0, 1, NULL, '4042', '', '', '', NULL, 'Blood', 'percentage', 15, 1, 'grouped', 'ho_widal', 'grouped', 'no', 'yes', 'yes', NULL, '2021-05-20 06:10:29', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'admin', 0, 4000, 'not allowed', 'WIDAL TEST Ab.', '', '', '', '', '', '', '', '', 1),
('', '40425', 3, 'S. Paratyphi C (O, H)', 0, 0, 4, NULL, '4042', '', '', '', NULL, 'Blood', 'percentage', 15, 1, 'grouped', 'ho_widal', 'grouped', 'no', 'yes', 'yes', NULL, '2021-05-20 06:10:29', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'admin', 0, 4000, 'not allowed', 'WIDAL TEST Ab.', '', '', '', '', '', '', '', '', 1),
(NULL, '4043', 3, 'Wound C/S', 3000, 3000, 4, '20003', '2022', '', '', '', '', 'Swab', 'percentage', 15, 1, 'single', 'microbiology_form', 'grouped', 'no', 'yes', 'yes', NULL, '2021-05-10 22:59:27', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 0, 4000, '', 'Wound C/S', '', '', '', '', '', '', '', '', 1),
(NULL, '4044', 3, 'Microbiology', 0, 0, 4, NULL, '4000', NULL, NULL, NULL, NULL, '', '', 0, 1, 'single', 'microbiology_form', 'grouped', 'no', 'yes', NULL, NULL, '2021-05-20 06:10:29', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 0, 4000, 'not allowed', 'Microbiology', '', '', '', '', '', '', '', '', 1),
('', '404432', 3, 'ASPIRATE M/C/S', 3000, 0, 31, '20003', '2022', '', '', '', NULL, 'Ascitic Fluid', 'percentage', 15, 1, 'single', 'microbiology_form', 'grouped', 'no', 'yes', 'yes', NULL, '2021-05-26 03:57:47', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'admin', 0, 4000, '', 'ASPIRATE M/C/S', '', '', '', '', '', '', '', '', 1),
('', '404433', 3, 'Helicobacter Pylori (Using Stool)', 2000, 0, 32, '20003', '2022', '', '', '', NULL, '', '', 0, 1, 'grouped', 'microbiology_form', 'grouped', 'no', NULL, NULL, NULL, '2021-05-28 04:51:37', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'admin', 0, 4000, '', 'Helicobacter Pylori (Using Stool)', '', '', '', '', '', '', '', '', 1),
('', '404434', 3, 'MANTOUX', 1000, 0, 33, '20003', '2022', '', '', '', NULL, '', '', 0, 1, 'single', 'microbiology_form', 'grouped', 'no', NULL, NULL, NULL, '2021-05-20 06:10:29', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'admin', 0, 4000, '', 'MANTOUX', '', '', '', '', '', '', '', '', 1),
('', '404435', 3, 'MASTOIDS', 4000, 0, 34, '20003', '2022', '', '', '', NULL, '', '', 0, 1, 'single', 'microbiology_form', 'grouped', 'no', NULL, NULL, NULL, '2021-05-20 06:10:29', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'admin', 0, 4000, '', 'MASTOIDS', '', '', '', '', '', '', '', '', 1),
(NULL, '404436', 3, 'ECS M/C/S', 3000, 3000, 0, '20004', '2022', '', '', '', '', 'Tissue/Vaginal Smear', 'percentage', 15, 1, 'grouped', NULL, 'grouped', 'no', 'yes', 'yes', NULL, '2021-05-26 04:04:46', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 0, 4000, '', 'ECS M/C/S', '', '', '', '', '', '', '', '', 1),
(NULL, '4045', 3, 'Serology', 0, 0, 1, NULL, '4000', NULL, NULL, NULL, NULL, '', '', 0, 1, 'single', NULL, 'grouped', 'no', 'yes', NULL, NULL, '2021-05-20 06:10:29', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 0, 4000, 'not allowed', 'Serology', '', '', '', '', '', '', '', '', 1),
('', '404512', 3, 'RVS Viral Load', 25000, 0, 11, '20003', '2022', '', '', '', NULL, '', '', 0, 1, 'grouped', 'input', 'grouped', 'no', NULL, NULL, NULL, '2021-05-28 04:53:12', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'admin', 0, 4000, '', 'RVS Viral Load', '', '', '', '', '', '', '', '', 1);

-- --------------------------------------------------------

--
-- Table structure for table `lab_setup2`
--

CREATE TABLE `lab_setup2` (
  `id` int(100) NOT NULL DEFAULT 0,
  `subhead` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `head` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `unit` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `range_from` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `range_to` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `specimen` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `price` int(100) DEFAULT NULL,
  `noOfLabels` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_at` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `created_by` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `lab_setup2`
--

INSERT INTO `lab_setup2` (`id`, `subhead`, `head`, `description`, `unit`, `range_from`, `range_to`, `specimen`, `price`, `noOfLabels`, `created_at`, `updated_at`, `facilityId`, `created_by`) VALUES
(2, '', 'Optimum Diagnostics', '', NULL, NULL, NULL, '', NULL, 0, '2020-08-16 01:30:37', NULL, '966a89f6-05d8-4564-b319-2f8863821e75', ''),
(72, 'Test', 'test1', '', 'mmol/L', '1', '2', 'Blood', 500, 0, '2020-09-18 08:48:58', NULL, '966a89f6-05d8-4564-b319-2f8863821e75', 'admin');

-- --------------------------------------------------------

--
-- Table structure for table `lab_setup3`
--

CREATE TABLE `lab_setup3` (
  `id` int(11) NOT NULL,
  `subhead` varchar(100) DEFAULT NULL,
  `head` varchar(100) DEFAULT NULL,
  `description` varchar(200) NOT NULL,
  `unit` varchar(100) DEFAULT NULL,
  `range_from` varchar(100) DEFAULT NULL,
  `range_to` varchar(100) DEFAULT NULL,
  `specimen` varchar(100) DEFAULT NULL,
  `price` int(100) DEFAULT NULL,
  `percentage` int(11) NOT NULL,
  `noOfLabels` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_at` varchar(100) DEFAULT NULL,
  `facilityId` varchar(50) NOT NULL,
  `created_by` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `lab_setup3`
--

INSERT INTO `lab_setup3` (`id`, `subhead`, `head`, `description`, `unit`, `range_from`, `range_to`, `specimen`, `price`, `percentage`, `noOfLabels`, `created_at`, `updated_at`, `facilityId`, `created_by`) VALUES
(1, '2000', '1000', 'Hematology', NULL, NULL, NULL, 'No specimen', NULL, 0, 0, '2020-11-15 22:55:46', NULL, '966a89f6-05d8-4564-b319-2f8863821e75', ''),
(361, '30013', '3001', 'K', 'mmol/L', '3.0', '5.6', 'Urine', 600, 0, 0, '2020-11-15 22:54:01', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'emaitee');

-- --------------------------------------------------------

--
-- Table structure for table `lab_setup4`
--

CREATE TABLE `lab_setup4` (
  `id` int(11) NOT NULL DEFAULT 0,
  `subhead` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `head` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `unit` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `range_from` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `range_to` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `other_range` varchar(50) DEFAULT NULL,
  `specimen` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `price` int(100) DEFAULT NULL,
  `percentage` int(11) NOT NULL,
  `noOfLabels` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_at` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `created_by` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `lab_setup4`
--

INSERT INTO `lab_setup4` (`id`, `subhead`, `head`, `description`, `unit`, `range_from`, `range_to`, `other_range`, `specimen`, `price`, `percentage`, `noOfLabels`, `created_at`, `updated_at`, `facilityId`, `created_by`) VALUES
(351, '1000', '', 'PSC Prime Lab', NULL, NULL, NULL, '', '', NULL, 0, 0, '0000-00-00 00:00:00', NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', ''),
(292, '5136', '5000', 'hs CRP', '', '', '', '', '', 2500, 0, 1, '2020-11-17 13:24:22', '', '966a89f6-05d8-4564-b319-2f8863821e75', '');

-- --------------------------------------------------------

--
-- Table structure for table `main_account`
--

CREATE TABLE `main_account` (
  `code` varchar(20) NOT NULL,
  `Description` varchar(50) NOT NULL,
  `type` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `main_account`
--

INSERT INTO `main_account` (`code`, `Description`, `type`) VALUES
('100010', 'Capital Account', 4),
('100020', 'Deposit Account', 4),
('100030', 'Suupliers Account', 4),
('600010', 'cash Account', 3),
('600020', 'Bank Account', 3),
('700010', 'Wages', 1),
('700020', 'Fuel', 1),
('800020', 'Drugs', 2),
('800010', 'Labs', 2);

-- --------------------------------------------------------

--
-- Stand-in structure for view `medication_report`
-- (See below for the actual view)
--
CREATE TABLE `medication_report` (
`patient_id` varchar(11)
,`drug` varchar(40)
,`dosage` varchar(40)
,`route` varchar(20)
,`time_stamp` timestamp
,`status` varchar(10)
,`served_by` varchar(50)
,`nurse_name` varchar(511)
,`reason` varchar(500)
);

-- --------------------------------------------------------

--
-- Table structure for table `members`
--

CREATE TABLE `members` (
  `name` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `members`
--

INSERT INTO `members` (`name`, `email`) VALUES
('adi', 'kamal'),
('abbba', 'sanio'),
('kamilu', 'danbata'),
('abba', 'collipad'),
('sarki', 'aliyu'),
('aminu', 'salim'),
('undefined', 'undefined'),
('undefined', 'undefined'),
('undefined', 'undefined'),
('undefined', 'undefined'),
('undefined', 'mubrak@gmail.ocm');

-- --------------------------------------------------------

--
-- Table structure for table `monthly_register`
--

CREATE TABLE `monthly_register` (
  `code` int(11) NOT NULL,
  `month` varchar(20) NOT NULL,
  `amount` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `number_generator`
--

CREATE TABLE `number_generator` (
  `description` varchar(100) NOT NULL,
  `prefix` varchar(100) NOT NULL,
  `code_no` int(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `number_generator`
--

INSERT INTO `number_generator` (`description`, `prefix`, `code_no`) VALUES
('Consultation with Dr. Nasir on 2025-04-27', 'DOC-ABD-20250427', 6),
('Consultation with Dr. Nasir on 2025-04-28', 'DOC-ABD-20250428', 21),
('Consultation with Dr. Nasir on 2025-04-30', 'DOC-ABD-20250430', 2),
('Consultation with Dr. Nasir on 2025-05-02', 'DOC-ABD-20250502', 1),
('Consultation with Dr. Nasir on 2025-05-03', 'DOC-ABD-20250503', 3),
('Consultation with Dr. Nasir on 2025-05-04', 'DOC-ABD-20250504', 5),
('Consultation with Dr. Nasir on 2025-05-05', 'DOC-ABD-20250505', 1),
('Consultation with Dr. Nasir on 2025-05-06', 'DOC-ABD-20250506', 3),
('Consultation with Dr. Nasir on 2025-05-07', 'DOC-ABD-20250507', 2),
('Consultation with Dr. Nasir on 2025-05-09', 'DOC-ABD-20250509', 6),
('Consultation with Dr. Nasir on 2025-05-11', 'DOC-ABD-20250511', 2),
('Consultation with Dr. Nasir on 2025-05-12', 'DOC-ABD-20250512', 6),
('Consultation with Dr. Nasir on 2025-05-15', 'DOC-ABD-20250515', 2),
('Consultation with Dr. Nasir on 2025-05-17', 'DOC-ABD-20250517', 4),
('Consultation with Dr. Nasir on 2025-05-18', 'DOC-ABD-20250518', 1),
('Consultation with Dr. Nasir on 2025-05-19', 'DOC-ABD-20250519', 1),
('Consultation with Dr. Nasir on 2025-05-20', 'DOC-ABD-20250520', 3),
('Consultation with Dr. Nasir on 2025-05-22', 'DOC-ABD-20250522', 10),
('Consultation with Dr. Nasir on 2025-05-23', 'DOC-ABD-20250523', 15),
('Consultation with Dr. Nasir on 2025-05-26', 'DOC-ABD-20250526', 5),
('Consultation with Dr. Nasir on 2025-05-28', 'DOC-ABD-20250528', 1),
('Consultation with Dr. Nasir on 2025-05-29', 'DOC-ABD-20250529', 1),
('Consultation with Dr. Nasir on 2025-07-04', 'DOC-ABD-20250704', 1),
('Consultation with Dr. Nasir on 2025-07-17', 'DOC-ABD-20250717', 1),
('Consultation with Dr. Nasir on 2025-08-10', 'DOC-ABD-20250810', 1),
('Consultation with Dr. Nasir on 2025-08-13', 'DOC-ABD-20250813', 1),
('Consultation with Dr. Nasir on 2025-10-30', 'DOC-ABD-20251030', 3),
('Consultation with Dr. Nasir on 2025-11-21', 'DOC-ABD-20251121', 1),
('Consultation with Dr. Nasir on 2025-11-22', 'DOC-ABD-20251122', 2),
('Consultation with Dr. Nasir on 2026-01-09', 'DOC-ABD-20260109', 1),
('Consultation with Dr. Babatunde on 2025-04-28', 'DOC-ADE-20250428', 2),
('Consultation with Dr. Dr Aluko on 2025-05-17', 'DOC-ALU-20250517', 2),
('Consultation with Dr. Chaba on 2025-05-18', 'DOC-CHA-20250518', 1),
('Consultation with Dr. Chaba on 2025-10-30', 'DOC-CHA-20251030', 1),
('Consultation with Dr. Bashir on 2025-05-17', 'DOC-DOC-20250517', 2),
('Consultation with Dr. Mukhtar on 2025-04-27', 'DOC-DRA-20250427', 1),
('Consultation with Dr. Makuku on 2025-04-28', 'DOC-DRM-20250428', 1),
('Consultation with Dr. Bashir on 2025-04-28', 'DOC-HAB-20250428', 1),
('Consultation with Dr. Ismail on 2025-04-27', 'DOC-HAS-20250427', 1),
('Consultation with Dr. Jinjiri on 2025-04-28', 'DOC-JIN-20250428', 1),
('Consultation with Dr. Ibrahim on 2025-04-28', 'DOC-MUS-20250428', 1),
('Consultation with Dr. Ibrahim on 2025-08-05', 'DOC-MUS-20250805', 1),
('Consultation with Dr. Oseni on 2025-04-30', 'DOC-OSE-20250430', 1),
('Consultation with Dr. Ramalan on 2025-04-28', 'DOC-RAM-20250428', 1),
('Consultation with Dr. Ramalan on 2025-08-10', 'DOC-RAM-20250810', 1),
('Consultation with Dr. haruna on 2025-04-27', 'DOC-SAD-20250427', 3),
('Consultation with Dr. haruna on 2025-04-28', 'DOC-SAD-20250428', 1),
('Consultation with Dr. haruna on 2025-04-30', 'DOC-SAD-20250430', 1),
('Consultation with Dr. haruna on 2025-05-03', 'DOC-SAD-20250503', 3),
('Consultation with Dr. haruna on 2025-05-04', 'DOC-SAD-20250504', 1),
('Consultation with Dr. haruna on 2025-05-09', 'DOC-SAD-20250509', 1),
('Consultation with Dr. haruna on 2025-05-12', 'DOC-SAD-20250512', 3),
('Consultation with Dr. haruna on 2025-05-17', 'DOC-SAD-20250517', 1),
('Good Receive Note', 'GRN', 9555),
('Goods transfer', 'trn', 1),
('Waiting List Consultation on 2025-04-27', 'WL-20250427', 6),
('Waiting List Consultation on 2025-04-28', 'WL-20250428', 15),
('Waiting List Consultation on 2025-04-29', 'WL-20250429', 1),
('Waiting List Consultation on 2025-04-30', 'WL-20250430', 4),
('Waiting List Consultation on 2025-05-02', 'WL-20250502', 12),
('Waiting List Consultation on 2025-05-03', 'WL-20250503', 8),
('Waiting List Consultation on 2025-05-04', 'WL-20250504', 3),
('Waiting List Consultation on 2025-05-05', 'WL-20250505', 3),
('Waiting List Consultation on 2025-05-06', 'WL-20250506', 9),
('Waiting List Consultation on 2025-05-07', 'WL-20250507', 18),
('Waiting List Consultation on 2025-05-09', 'WL-20250509', 8),
('Waiting List Consultation on 2025-05-11', 'WL-20250511', 3),
('Waiting List Consultation on 2025-05-12', 'WL-20250512', 6),
('Waiting List Consultation on 2025-05-15', 'WL-20250515', 3),
('Waiting List Consultation on 2025-05-16', 'WL-20250516', 2),
('Waiting List Consultation on 2025-05-17', 'WL-20250517', 7),
('Waiting List Consultation on 2025-05-18', 'WL-20250518', 2),
('Waiting List Consultation on 2025-05-19', 'WL-20250519', 1),
('Waiting List Consultation on 2025-05-20', 'WL-20250520', 4),
('Waiting List Consultation on 2025-05-22', 'WL-20250522', 7),
('Waiting List Consultation on 2025-05-28', 'WL-20250528', 4),
('Waiting List Consultation on 2025-07-01', 'WL-20250701', 17),
('Waiting List Consultation on 2025-07-04', 'WL-20250704', 1),
('Waiting List Consultation on 2025-07-17', 'WL-20250717', 1),
('Waiting List Consultation on 2025-07-23', 'WL-20250723', 2),
('Waiting List Consultation on 2025-08-10', 'WL-20250810', 3),
('Waiting List Consultation on 2025-10-07', 'WL-20251007', 1),
('Waiting List Consultation on 2025-10-24', 'WL-20251024', 1),
('Waiting List Consultation on 2025-10-30', 'WL-20251030', 2),
('Waiting List Consultation on 2025-11-12', 'WL-20251112', 4),
('Waiting List Consultation on 2025-11-21', 'WL-20251121', 1),
('Waiting List Consultation on 2026-01-09', 'WL-20260109', 2);

-- --------------------------------------------------------

--
-- Table structure for table `nursing_note`
--

CREATE TABLE `nursing_note` (
  `id` int(11) NOT NULL,
  `report` varchar(150) DEFAULT NULL,
  `patient_id` varchar(20) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) DEFAULT NULL,
  `facilityId` varchar(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nursing_report`
--

CREATE TABLE `nursing_report` (
  `id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `report` varchar(2000) NOT NULL,
  `facilityId` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `nursing_report`
--

INSERT INTO `nursing_report` (`id`, `created_at`, `created_by`, `report`, `facilityId`) VALUES
(1, '2025-05-09 14:32:35', 'abdurrahman', 'oiuytmfkwehuf jkbfrv grebgruj gbrg trgugb r like whis r he. was. a amsnd nhfnje', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `operationnotes`
--

CREATE TABLE `operationnotes` (
  `facilityId` varchar(50) DEFAULT NULL,
  `id` int(11) NOT NULL,
  `uuid` varchar(50) DEFAULT NULL,
  `date` varchar(20) DEFAULT NULL,
  `patientId` varchar(10) NOT NULL,
  `diagnosis` varchar(150) DEFAULT NULL,
  `surgeons` varchar(300) DEFAULT NULL,
  `surgery` varchar(150) DEFAULT NULL,
  `anesthetist` varchar(80) DEFAULT NULL,
  `anesthetic` varchar(20) DEFAULT NULL,
  `scrubNurse` varchar(50) DEFAULT NULL,
  `remarks` varchar(50) DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `pintsGiven` varchar(10) DEFAULT NULL,
  `bloodLoss` varchar(15) DEFAULT NULL,
  `intraOpAntibiotics` varchar(20) DEFAULT NULL,
  `intraOpFindings` varchar(2000) DEFAULT NULL,
  `procedureNotes` varchar(2000) DEFAULT NULL,
  `pathologyRequest` varchar(2000) DEFAULT NULL,
  `postOpOrder` varchar(1500) DEFAULT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` varchar(50) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `operationnotes`
--

INSERT INTO `operationnotes` (`facilityId`, `id`, `uuid`, `date`, `patientId`, `diagnosis`, `surgeons`, `surgery`, `anesthetist`, `anesthetic`, `scrubNurse`, `remarks`, `name`, `pintsGiven`, `bloodLoss`, `intraOpAntibiotics`, `intraOpFindings`, `procedureNotes`, `pathologyRequest`, `postOpOrder`, `createdAt`, `updatedAt`) VALUES
('', 2193, '', '2025-07-14', '', 'Tonsillitis', 'Dr. Abdurrahman', 'Tonsilllectomy', 'Dr. Dalhat Salahu', 'GA', '', '', NULL, '20', 'xlm', '291', '', '', '', '', '2025-07-14 12:02:36', NULL),
('', 2182, '', '2025-07-14', '', 'Tonsillitis		', 'Dr. Abdurrahman', 'Tonsilllectomy', 'Dr. Dalhat Salahu', 'GA', '', 'small', NULL, '20', 'xlm', '291', 'small', 'small', 'small', 'small', '2025-07-14 09:59:24', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 2258, '', '2025-08-11', '33-1', 'Tonsillitis', 'Dr. Nasiru Jinjiri,Dr. Abdurrahman', 'Tonsilllectomy', 'Dr. Dalhat Salahu,Dr Abubakar Nagoma', 'Spinal/Epidural', '', 'Everything was done and no mistake ', 'Solomn David', '20', 'xlm', '291', 'TonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomy', 'TonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomy', 'TonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomy', 'TonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomy', '2025-08-11 07:01:43', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 2259, '', '2025-10-07', '31-1', '', 'Dr. Abdurrahman,Dr. Hassan Ismail', '', 'Dr. Dalhat Salahu', 'GA', '', '', 'Today Today', '', '', '', '', '', '', '', '2025-08-11 07:27:10', '2025-10-07 14:29:10'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 2260, '', '2025-08-11', '25-1', 'Tonsillitis', '', 'Tonsilllectomy', '', 'Spinal/Epidural', '', 'Everything was done and no mistake ', 'Solar Solar', '20', 'xlm', '291', 'TonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomy', 'TonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomy', 'TonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomy', 'TonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomyTonsilllectomy', '2025-10-07 14:40:30', NULL);

--
-- Triggers `operationnotes`
--
DELIMITER $$
CREATE TRIGGER `default_date` BEFORE INSERT ON `operationnotes` FOR EACH ROW if ( isnull(new.date) ) then
 set new.date=curdate();
end if
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `set_op_notes_updateAt` BEFORE UPDATE ON `operationnotes` FOR EACH ROW SET NEW.updatedAt = NOW()
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `overview`
-- (See below for the actual view)
--
CREATE TABLE `overview` (
`drug` varchar(20)
,`quantity_bought` int(11)
,`amount_bought` double
,`quantity_in_store` varchar(50)
,`amount_in_store` double
,`quantity_sold` int(11)
,`amount_sold` bigint(22)
,`quantity_in_shelf` bigint(12)
,`amount_in_shelf` bigint(23)
,`sales_date` timestamp
,`purchase_date` datetime
,`facilityId` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `overview_wo_store`
-- (See below for the actual view)
--
CREATE TABLE `overview_wo_store` (
`drug` varchar(20)
,`price` bigint(12)
,`quantity_in_shelf` decimal(33,0)
,`amount_in_shelf` decimal(44,0)
,`quantity_sold` decimal(33,0)
,`amount_sold` decimal(44,0)
,`expiry_date` varchar(10)
,`created_at` timestamp
,`facilityId` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `pagenavigation`
--

CREATE TABLE `pagenavigation` (
  `id` int(11) NOT NULL,
  `role` varchar(30) NOT NULL,
  `home_page` varchar(100) NOT NULL,
  `facilityId` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pagenavigation`
--

INSERT INTO `pagenavigation` (`id`, `role`, `home_page`, `facilityId`) VALUES
(1, 'Cashier', '/me/account/review', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(2, 'Receptionist', '/me/records/patients/list', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(3, 'Technician', '/me/lab/sample-collection', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(4, 'Sample Collector', '/me/lab/sample-collection', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(5, 'Doctor', '/me/doctor', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(6, 'Sample Collection', '/me/lab/sample-collection', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(7, 'Scientist', '/me/lab/patients', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(8, 'Accountant', '/me/account/report', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(9, 'Lab Scientist', '/me/lab', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(10, 'Manager', '/me/account/services', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(11, 'Admin', '/me/admin', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(12, 'IT Staff', '/me/pharmacy', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(13, 'Nurse', '/me/nurse/vital-signs', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(14, 'Neurosurgeon', '/me/doctor', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `patientfileinfo`
--

CREATE TABLE `patientfileinfo` (
  `id` int(11) NOT NULL,
  `accountNo` varchar(7) NOT NULL,
  `firstname` varchar(50) NOT NULL,
  `surname` varchar(50) NOT NULL,
  `beneficiaries` int(5) NOT NULL,
  `balance` int(11) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `patientfileno`
--

CREATE TABLE `patientfileno` (
  `id` int(11) NOT NULL,
  `facilityId` varchar(50) DEFAULT NULL,
  `accountNo` int(7) DEFAULT NULL,
  `accName` varchar(50) DEFAULT NULL,
  `description` varchar(100) DEFAULT NULL,
  `accountType` varchar(50) DEFAULT NULL,
  `contactName` varchar(100) DEFAULT NULL,
  `contactAddress` varchar(500) DEFAULT NULL,
  `contactPhone` varchar(20) DEFAULT NULL,
  `contactEmail` varchar(50) DEFAULT NULL,
  `contactWebsite` varchar(50) DEFAULT NULL,
  `firstname` varchar(50) DEFAULT NULL,
  `surname` varchar(50) DEFAULT NULL,
  `beneficiaries` bigint(21) NOT NULL DEFAULT 0,
  `balance` int(11) NOT NULL DEFAULT 0,
  `status` varchar(50) NOT NULL DEFAULT 'approved',
  `guarantor_name` varchar(50) DEFAULT NULL,
  `guarantor_address` varchar(100) DEFAULT NULL,
  `guarantor_phone` varchar(20) DEFAULT NULL,
  `created_by` varchar(50) DEFAULT NULL,
  `approved_by` varchar(50) DEFAULT NULL,
  `createdAt` timestamp NULL DEFAULT current_timestamp(),
  `approved_at` timestamp NULL DEFAULT NULL,
  `payable_head_name` varchar(150) DEFAULT NULL,
  `payable_head` varchar(50) DEFAULT NULL,
  `receivable_head_name` varchar(150) DEFAULT NULL,
  `receivable_head` varchar(50) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `patientfileno`
--

INSERT INTO `patientfileno` (`id`, `facilityId`, `accountNo`, `accName`, `description`, `accountType`, `contactName`, `contactAddress`, `contactPhone`, `contactEmail`, `contactWebsite`, `firstname`, `surname`, `beneficiaries`, `balance`, `status`, `guarantor_name`, `guarantor_address`, `guarantor_phone`, `created_by`, `approved_by`, `createdAt`, `approved_at`, `payable_head_name`, `payable_head`, `receivable_head_name`, `receivable_head`) VALUES
(1, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 1, 'John Doe', NULL, 'Single', NULL, '', '09087654321', '', '', NULL, NULL, 89, -557012, 'approved', '', '', '', NULL, NULL, '2024-08-10 13:52:20', NULL, NULL, NULL, NULL, NULL),
(2, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 2, 'Marilyn Montana', NULL, 'Single', NULL, '', '09012121212', '', '', NULL, NULL, 0, 512300, 'approved', '', '', '', NULL, NULL, '2024-08-12 07:46:59', NULL, NULL, NULL, NULL, NULL),
(3, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 3, 'Nazif Musa', NULL, 'Single', NULL, '', '09023232323', '', '', NULL, NULL, 0, -518990, 'approved', '', '', '', NULL, NULL, '2024-08-19 13:06:11', NULL, NULL, NULL, NULL, NULL),
(4, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 4, 'Poloa Main', NULL, 'Single', NULL, '', '09090121212', '', '', NULL, NULL, 0, 271200, 'approved', '', '', '', NULL, NULL, '2024-08-19 13:11:46', NULL, NULL, NULL, NULL, NULL),
(5, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 5, 'NAF Patient', NULL, 'Single', NULL, '', '090', '', '', NULL, NULL, 0, 178260, 'approved', '', '', '', NULL, NULL, '2024-08-20 10:16:24', NULL, NULL, NULL, NULL, NULL),
(6, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 6, 'Musa Isah', NULL, 'Single', NULL, '', '09012121212', '', '', NULL, NULL, 0, -536295, 'approved', '', '', '', NULL, NULL, '2024-09-10 11:07:33', NULL, NULL, NULL, NULL, NULL),
(7, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 7, 'Nagudu Maibaki', NULL, 'Single', NULL, '', '09012121212', '', '', NULL, NULL, 0, -4195, 'approved', '', '', '', NULL, NULL, '2024-09-10 11:11:34', NULL, NULL, NULL, NULL, NULL),
(8, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 8, 'Murtala Dodo', NULL, 'Single', NULL, '', '09012121222', '', '', NULL, NULL, 0, -38585, 'approved', '', '', '', NULL, NULL, '2024-09-10 11:30:44', NULL, NULL, NULL, NULL, NULL),
(9, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 9, 'New Patient', NULL, 'Single', NULL, '', '09017901953', '', '', NULL, NULL, 0, -23595, 'approved', '', '', '', NULL, NULL, '2025-02-18 13:05:22', NULL, NULL, NULL, NULL, NULL),
(10, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 10, 'Frank Sadiq', NULL, 'Single', NULL, 'Kano', '07032151593', '', '', NULL, NULL, 0, 36500, 'approved', '', '', '', NULL, NULL, '2025-02-20 08:27:24', NULL, NULL, NULL, NULL, NULL),
(11, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 11, 'Love Love', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, 400000, 'approved', '', '', '', NULL, NULL, '2025-02-20 08:29:30', NULL, NULL, NULL, NULL, NULL),
(12, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 12, 'Fg Fg', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, 200000, 'approved', '', '', '', NULL, NULL, '2025-02-20 08:56:26', NULL, NULL, NULL, NULL, NULL),
(13, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 13, 'Change Change', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -20400, 'approved', '', '', '', NULL, NULL, '2025-02-20 08:58:33', NULL, NULL, NULL, NULL, NULL),
(14, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 14, 'Kadiri Haruna', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -3585, 'approved', '', '', '', NULL, NULL, '2025-02-20 11:08:51', NULL, NULL, NULL, NULL, NULL),
(15, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 15, 'Usman Usman', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -29405, 'approved', '', '', '', NULL, NULL, '2025-02-20 11:10:14', NULL, NULL, NULL, NULL, NULL),
(16, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 16, 'Praise  Praise', NULL, 'Single', NULL, 'Kano', '07032151593', '', '', NULL, NULL, 0, -44940, 'approved', '', '', '', NULL, NULL, '2025-02-20 11:17:54', NULL, NULL, NULL, NULL, NULL),
(17, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 17, 'Ozoz Ozoz', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, 153531, 'approved', '', '', '', NULL, NULL, '2025-02-20 12:10:37', NULL, NULL, NULL, NULL, NULL),
(18, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 18, 'Xray Xray', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -70784, 'approved', '', '', '', NULL, NULL, '2025-02-20 13:48:14', NULL, NULL, NULL, NULL, NULL),
(19, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 19, 'Qq Qqq', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -95494, 'approved', '', '', '', NULL, NULL, '2025-02-20 14:29:00', NULL, NULL, NULL, NULL, NULL),
(20, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 20, 'Zubairu Kalthum', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -478482, 'approved', '', '', '', NULL, NULL, '2025-04-27 19:51:31', NULL, NULL, NULL, NULL, NULL),
(21, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 21, 'Amina Amina', NULL, 'Family', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -92794, 'approved', '', '', '', NULL, NULL, '2025-04-30 09:43:51', NULL, NULL, NULL, NULL, NULL),
(22, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 22, 'Jaki Jaki', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -76290, 'approved', '', '', '', NULL, NULL, '2025-04-30 13:58:06', NULL, NULL, NULL, NULL, NULL),
(23, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 23, 'Bakura Mustapha', NULL, 'Single', NULL, 'BABABABABAB ', '07032151593', '', '', NULL, NULL, 0, -42993, 'approved', '', '', '', NULL, NULL, '2025-04-30 16:15:56', NULL, NULL, NULL, NULL, NULL),
(24, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 24, 'Kate Kate', NULL, 'Family', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -247475, 'approved', '', '', '', NULL, NULL, '2025-05-03 13:31:45', NULL, NULL, NULL, NULL, NULL),
(25, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 25, 'Solar Solar', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -100294, 'approved', '', '', '', NULL, NULL, '2025-05-03 13:38:23', NULL, NULL, NULL, NULL, NULL),
(26, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 26, 'Bb Bb', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -39296, 'approved', '', '', '', NULL, NULL, '2025-05-03 16:45:12', NULL, NULL, NULL, NULL, NULL),
(27, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 27, 'Aa Aa', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -3000, 'approved', '', '', '', NULL, NULL, '2025-05-03 16:45:35', NULL, NULL, NULL, NULL, NULL),
(28, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 28, 'Boss Boss', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -4339372, 'approved', '', '', '', NULL, NULL, '2025-05-03 16:46:04', NULL, NULL, NULL, NULL, NULL),
(29, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 29, 'Testprime Testprime', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, 0, 'approved', '', '', '', NULL, NULL, '2025-05-06 08:43:41', NULL, NULL, NULL, NULL, NULL),
(30, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 30, 'Moily Mily', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, 17603, 'approved', '', '', '', NULL, NULL, '2025-05-09 08:15:39', NULL, NULL, NULL, NULL, NULL),
(31, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 31, 'Today Today', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -854925, 'approved', '', '', '', NULL, NULL, '2025-05-09 08:16:42', NULL, NULL, NULL, NULL, NULL),
(32, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 32, 'Wooo Oooo', NULL, 'Family', NULL, 'Kano naibawa', '0909876542', '', '', NULL, NULL, 0, 0, 'approved', '', '', '', NULL, NULL, '2025-05-18 10:29:23', NULL, NULL, NULL, NULL, NULL),
(33, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 33, 'Solomn David', NULL, 'Single', NULL, 'Kano naibawa', '08022151593', '', '', NULL, NULL, 0, -728919, 'approved', '', '', '', NULL, NULL, '2025-05-20 09:16:00', NULL, NULL, NULL, NULL, NULL),
(34, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 34, 'Fgfff Sadiq', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, -1100, 'approved', '', '', '', NULL, NULL, '2025-06-25 09:38:31', NULL, NULL, NULL, NULL, NULL),
(35, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 35, 'Mustapha Aminu', NULL, 'Single', NULL, '', '09012345678', '', '', NULL, NULL, 0, -26000, 'approved', '', '', '', NULL, NULL, '2025-07-04 10:32:20', NULL, NULL, NULL, NULL, NULL),
(36, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 36, 'OBAMA FESTUS', NULL, 'Retainership', NULL, 'Kano naibawa', '07032151592', '', '', NULL, NULL, 0, 0, 'approved', '', '', '', NULL, NULL, '2025-10-07 10:13:28', NULL, NULL, NULL, NULL, NULL),
(37, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 37, 'Bashir Sadiq', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, 0, 'approved', '', '', '', NULL, NULL, '2025-10-28 11:14:51', NULL, NULL, NULL, NULL, NULL),
(38, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 38, 'Khadija Haruna', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, 0, 'approved', '', '', '', NULL, NULL, '2025-11-14 13:19:34', NULL, NULL, NULL, NULL, NULL),
(39, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 39, 'Sani Fatima ', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, 0, 'approved', '', '', '', NULL, NULL, '2025-11-19 18:45:53', NULL, NULL, NULL, NULL, NULL),
(40, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 40, 'Kabir Kabir', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, 0, 'approved', '', '', '', NULL, NULL, '2025-11-20 16:20:51', NULL, NULL, NULL, NULL, NULL),
(41, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 41, 'Lydia Sadiq', NULL, 'Single', NULL, 'Kano naibawa', '07032151593', '', '', NULL, NULL, 0, 0, 'approved', '', '', '', NULL, NULL, '2025-11-21 11:42:13', NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `patientfileno2`
--

CREATE TABLE `patientfileno2` (
  `id` int(11) NOT NULL DEFAULT 0,
  `facilityId` varchar(50) DEFAULT NULL,
  `accountNo` int(7) DEFAULT NULL,
  `accName` varchar(50) DEFAULT NULL,
  `description` varchar(100) DEFAULT NULL,
  `accountType` varchar(50) DEFAULT NULL,
  `contactName` varchar(100) DEFAULT NULL,
  `contactAddress` varchar(500) DEFAULT NULL,
  `contactPhone` varchar(20) DEFAULT NULL,
  `contactEmail` varchar(50) DEFAULT NULL,
  `contactWebsite` varchar(50) DEFAULT NULL,
  `firstname` varchar(50) DEFAULT NULL,
  `surname` varchar(50) DEFAULT NULL,
  `beneficiaries` bigint(21) NOT NULL DEFAULT 0,
  `balance` int(11) NOT NULL DEFAULT 0,
  `status` varchar(50) NOT NULL DEFAULT 'pending',
  `guarantor_name` varchar(50) DEFAULT NULL,
  `guarantor_address` varchar(100) DEFAULT NULL,
  `guarantor_phone` varchar(20) DEFAULT NULL,
  `created_by` varchar(50) DEFAULT NULL,
  `approved_by` varchar(50) DEFAULT NULL,
  `createdAt` timestamp NULL DEFAULT current_timestamp(),
  `approved_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `patientfileno2`
--

INSERT INTO `patientfileno2` (`id`, `facilityId`, `accountNo`, `accName`, `description`, `accountType`, `contactName`, `contactAddress`, `contactPhone`, `contactEmail`, `contactWebsite`, `firstname`, `surname`, `beneficiaries`, `balance`, `status`, `guarantor_name`, `guarantor_address`, `guarantor_phone`, `created_by`, `approved_by`, `createdAt`, `approved_at`) VALUES
(1, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 238, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Abba', 'Sulaiman', 2, 0, 'pending', NULL, NULL, NULL, NULL, NULL, '2019-12-19 07:29:26', NULL),
(8237, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 4678, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Salisu', 'Sani', 1, 0, 'pending', NULL, NULL, NULL, NULL, NULL, '2020-12-03 05:33:53', NULL);

-- --------------------------------------------------------

--
-- Stand-in structure for view `patientfileno_full`
-- (See below for the actual view)
--
CREATE TABLE `patientfileno_full` (
`id` int(11)
,`acc_count` bigint(21)
,`accountNo` int(7)
,`beneficiaries` bigint(21)
,`firstname` varchar(50)
,`surname` varchar(50)
,`status` varchar(50)
,`createdAt` timestamp
,`accName` varchar(50)
,`description` varchar(100)
,`accountType` varchar(50)
,`contactName` varchar(100)
,`contactAddress` varchar(500)
,`contactPhone` varchar(20)
,`contactEmail` varchar(50)
,`contactWebsite` varchar(50)
,`balance` int(11)
,`guarantor_name` varchar(50)
,`guarantor_address` varchar(100)
,`guarantor_phone` varchar(20)
,`created_by` varchar(50)
,`approved_by` varchar(50)
,`approved_at` timestamp
);

-- --------------------------------------------------------

--
-- Table structure for table `patientfileno_test`
--

CREATE TABLE `patientfileno_test` (
  `id` int(11) NOT NULL DEFAULT 0,
  `acc_count` bigint(21) NOT NULL DEFAULT 0,
  `accountNo` int(7) DEFAULT NULL,
  `beneficiaries` bigint(21) NOT NULL DEFAULT 0,
  `firstname` varchar(50) DEFAULT NULL,
  `surname` varchar(50) DEFAULT NULL,
  `status` varchar(50) NOT NULL DEFAULT 'pending',
  `createdAt` timestamp NULL DEFAULT NULL,
  `accName` varchar(50) DEFAULT NULL,
  `description` varchar(100) DEFAULT NULL,
  `accountType` varchar(50) DEFAULT NULL,
  `contactName` varchar(100) DEFAULT NULL,
  `contactAddress` varchar(500) DEFAULT NULL,
  `contactPhone` varchar(20) DEFAULT NULL,
  `contactEmail` varchar(50) DEFAULT NULL,
  `contactWebsite` varchar(50) DEFAULT NULL,
  `balance` int(11) NOT NULL DEFAULT 0,
  `guarantor_name` varchar(50) DEFAULT NULL,
  `guarantor_address` varchar(100) DEFAULT NULL,
  `guarantor_phone` varchar(20) DEFAULT NULL,
  `created_by` varchar(50) DEFAULT NULL,
  `approved_by` varchar(50) DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `patientfileno_test`
--

INSERT INTO `patientfileno_test` (`id`, `acc_count`, `accountNo`, `beneficiaries`, `firstname`, `surname`, `status`, `createdAt`, `accName`, `description`, `accountType`, `contactName`, `contactAddress`, `contactPhone`, `contactEmail`, `contactWebsite`, `balance`, `guarantor_name`, `guarantor_address`, `guarantor_phone`, `created_by`, `approved_by`, `approved_at`) VALUES
(7563, 1, 1, 1, 'Hauwa', 'Musbahu', 'pending', '2020-12-03 05:33:53', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(8237, 1, 4678, 1, 'Salisu', 'Sani', 'pending', '2020-12-03 05:33:53', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `patientrecords`
--

CREATE TABLE `patientrecords` (
  `facilityId` varchar(50) NOT NULL,
  `title` varchar(10) DEFAULT NULL,
  `accountType` varchar(50) DEFAULT NULL,
  `surname` varchar(50) DEFAULT NULL,
  `firstname` varchar(50) DEFAULT NULL,
  `other` varchar(50) DEFAULT NULL,
  `Gender` varchar(10) DEFAULT NULL,
  `age` int(3) DEFAULT 0,
  `maritalstatus` varchar(20) DEFAULT '0',
  `DOB` varchar(20) DEFAULT NULL,
  `dateCreated` varchar(50) DEFAULT NULL,
  `phoneNo` varchar(30) DEFAULT '',
  `email` varchar(50) DEFAULT '',
  `state` varchar(50) DEFAULT '',
  `lga` varchar(50) DEFAULT '',
  `occupation` varchar(50) DEFAULT '',
  `address` varchar(500) DEFAULT '',
  `kinName` varchar(100) DEFAULT '',
  `kinRelationship` varchar(20) DEFAULT '',
  `kinPhone` varchar(30) DEFAULT '0',
  `kinEmail` varchar(50) DEFAULT '0',
  `kinAddress` varchar(500) DEFAULT '0',
  `accountNo` int(7) DEFAULT NULL,
  `beneficiaryNo` int(3) DEFAULT NULL,
  `balance` int(11) DEFAULT 0,
  `id` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `patient_id` int(11) NOT NULL,
  `enteredBy` varchar(20) DEFAULT NULL,
  `patientStatus` varchar(50) DEFAULT NULL,
  `assigned_to` varchar(20) DEFAULT NULL,
  `createdAt` varchar(20) DEFAULT NULL,
  `date_assigned` timestamp NULL DEFAULT NULL,
  `status` varchar(50) DEFAULT 'pending_registration',
  `hematology` varchar(20) DEFAULT NULL,
  `microbiology` varchar(20) DEFAULT NULL,
  `chem_path` varchar(20) DEFAULT NULL,
  `radiology` varchar(20) DEFAULT NULL,
  `seen_by` varchar(50) DEFAULT NULL,
  `date_seen` datetime DEFAULT NULL,
  `patient_passport` varchar(100) DEFAULT NULL,
  `enrollee_no` varchar(50) DEFAULT NULL,
  `insurance_scheme` varchar(50) DEFAULT NULL,
  `hmo` varchar(50) DEFAULT NULL,
  `organization` varchar(200) DEFAULT NULL,
  `consultation_number` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `patientrecords`
--

INSERT INTO `patientrecords` (`facilityId`, `title`, `accountType`, `surname`, `firstname`, `other`, `Gender`, `age`, `maritalstatus`, `DOB`, `dateCreated`, `phoneNo`, `email`, `state`, `lga`, `occupation`, `address`, `kinName`, `kinRelationship`, `kinPhone`, `kinEmail`, `kinAddress`, `accountNo`, `beneficiaryNo`, `balance`, `id`, `patient_id`, `enteredBy`, `patientStatus`, `assigned_to`, `createdAt`, `date_assigned`, `status`, `hematology`, `microbiology`, `chem_path`, `radiology`, `seen_by`, `date_seen`, `patient_passport`, `enrollee_no`, `insurance_scheme`, `hmo`, `organization`, `consultation_number`) VALUES
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 'Single', 'Signle', 'File', '', 'Male', 0, 'Single', '1971-01-09', '2026-01-09', '09020203030', '', '', '', 'Teacber', '', 'Musa', '', '', '', '', 1, 1, 0, '1-1', 1, NULL, NULL, 'waiting', NULL, '2026-01-09 16:09:41', 'waiting', NULL, NULL, NULL, NULL, NULL, '2026-01-09 16:09:41', 'undefined', '', 'undefined', 'undefined', 'undefined', 'WL-20260109-002'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 'Family', 'Family', 'Account', '', 'Male', 0, 'Single', '1983-01-09', '2026-01-09', '09020202002', '', '', '', '', '', '', '', '', '', '', 2, 1, 0, '2-1', 2, NULL, NULL, '', NULL, NULL, 'waiting', NULL, NULL, NULL, NULL, NULL, '2026-01-09 15:49:31', 'undefined', '', 'undefined', 'undefined', 'undefined', 'DOC-ABD-20260109-001'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 'Cooporate', 'Dala Rice', 'Mills', '', '', 0, 'Single', '2026-01-09', '2026-01-09', '', '', '', '', '', '', '', '', '', '', '', 3, 1, 0, '3-1', 3, NULL, NULL, NULL, NULL, NULL, 'registered', NULL, NULL, NULL, NULL, NULL, '2026-01-09 16:04:53', 'undefined', '', 'undefined', 'undefined', 'undefined', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', 'Single', 'Ishaq', 'Ibrahim', '', 'Male', 0, 'Married', '1971-01-09', '2026-01-09', '09034042030', '', '', '', '', '', '', '', '', '', '', 4, 1, 0, '4-1', 4, NULL, NULL, NULL, NULL, NULL, 'registered', NULL, NULL, NULL, NULL, NULL, '2026-01-09 16:12:23', 'undefined', '', 'undefined', 'undefined', 'undefined', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `patientrecords_bkp`
--

CREATE TABLE `patientrecords_bkp` (
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `title` varchar(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `accountType` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `surname` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `firstname` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `other` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `Gender` varchar(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `age` int(3) DEFAULT 0,
  `maritalstatus` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '0',
  `DOB` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `dateCreated` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `phoneNo` varchar(30) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `email` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `state` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `lga` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `occupation` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `address` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `kinName` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `kinRelationship` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `kinPhone` varchar(30) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '0',
  `kinEmail` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '0',
  `kinAddress` varchar(500) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '0',
  `accountNo` int(7) DEFAULT NULL,
  `beneficiaryNo` int(3) DEFAULT NULL,
  `balance` int(11) DEFAULT 0,
  `id` varchar(10) NOT NULL,
  `patient_id` int(11) NOT NULL DEFAULT 0,
  `enteredBy` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `patientStatus` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `assigned_to` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `createdAt` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `date_assigned` datetime DEFAULT NULL,
  `status` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT 'registered',
  `hematology` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `microbiology` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `chem_path` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `radiology` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `seen_by` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `date_seen` datetime DEFAULT NULL,
  `patient_passport` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `patient_ai_summaries`
--

CREATE TABLE `patient_ai_summaries` (
  `id` int(11) NOT NULL,
  `patient_id` varchar(50) NOT NULL,
  `summary` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `patient_bed`
-- (See below for the actual view)
--
CREATE TABLE `patient_bed` (
`allocation_id` int(11)
,`bed_id` int(11)
,`allocated` timestamp
,`allocated_by` varchar(50)
,`allocation_status` varchar(20)
,`patient_name` varchar(101)
,`patient_id` varchar(50)
,`accountNo` int(7)
,`facilityId` varchar(50)
,`status` varchar(50)
,`seen_by` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `patient_history`
--

CREATE TABLE `patient_history` (
  `id` int(11) NOT NULL,
  `patient_id` varchar(50) NOT NULL,
  `request_id` int(11) NOT NULL,
  `history` varchar(1000) NOT NULL,
  `file` varchar(200) NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `facilityId` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `patient_history`
--

INSERT INTO `patient_history` (`id`, `patient_id`, `request_id`, `history`, `file`, `createdAt`, `facilityId`) VALUES
(0, '2-1', 8, '', '', '2026-01-09 16:01:43', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(1, '7-1', 1, '', '', '2021-09-28 11:55:25', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(2, '8-1', 2, '', '', '2021-09-28 14:45:15', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(3, '329-1', 1, '', '', '2021-10-01 03:24:39', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(4, '329-1', 2, '', '', '2021-10-01 03:25:04', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(1000, '1599-1', 0, '', '', '2022-04-30 04:25:40', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `pending_lab_txn`
--

CREATE TABLE `pending_lab_txn` (
  `account` int(11) NOT NULL,
  `description` varchar(100) NOT NULL,
  `group_head` varchar(20) NOT NULL,
  `price` int(11) NOT NULL,
  `test` varchar(50) NOT NULL,
  `request_id` varchar(50) NOT NULL,
  `status` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pending_lab_txn`
--

INSERT INTO `pending_lab_txn` (`account`, `description`, `group_head`, `price`, `test`, `request_id`, `status`) VALUES
(20001, 'Full Blood Count', '2021', 2200, '2021', 'a8c6aa2e-98cc-411f-a202-82dcf9ea430a', 'pending'),
(20002, 'URINE ELECTROLYTE', '0', 3000, '30088', 'a8c6aa2e-98cc-411f-a202-82dcf9ea430a', 'pending'),
(20003, 'HBs Ag', '0', 1400, '4012', 'a8c6aa2e-98cc-411f-a202-82dcf9ea430a', 'pending'),
(20003, 'HIV Viral Load', '0', 25000, '4014', 'a8c6aa2e-98cc-411f-a202-82dcf9ea430a', 'pending'),
(20002, 'RPG/RBS', '0', 800, '30072', 'a8c6aa2e-98cc-411f-a202-82dcf9ea430a', 'pending'),
(20001, 'Clothing Profile', '2019', 5000, '2019', 'a8c6aa2e-98cc-411f-a202-82dcf9ea430a', 'pending'),
(20003, 'HCV Ab', '0', 1400, '4013', 'a8c6aa2e-98cc-411f-a202-82dcf9ea430a', 'pending'),
(20001, 'Full Blood Count', '2021', 2200, '2021', '7670d011-e56b-48c6-a79e-1ca55a00f7f0', 'pending'),
(20002, 'Urea, Electrolyte & Creatinine', '30095', 3000, '30095', '7670d011-e56b-48c6-a79e-1ca55a00f7f0', 'pending'),
(20002, 'PSA', '0', 5500, '30066', '7670d011-e56b-48c6-a79e-1ca55a00f7f0', 'pending'),
(20003, 'MALARIA PARASITES', '0', 700, '4020', '7670d011-e56b-48c6-a79e-1ca55a00f7f0', 'pending'),
(20001, 'ESR', '0', 1200, '2009', '7670d011-e56b-48c6-a79e-1ca55a00f7f0', 'pending'),
(20002, 'RPG/RBS', '0', 800, '30072', '7670d011-e56b-48c6-a79e-1ca55a00f7f0', 'pending'),
(20002, 'Calcium', '0', 800, '30027', 'ce88aea7-a50b-40a1-9394-224a0b9f28c8', 'pending'),
(20002, 'Uric Acid', '0', 1000, '30092', 'ce88aea7-a50b-40a1-9394-224a0b9f28c8', 'pending'),
(20001, 'PCV', '0', 700, '2001', 'b809144a-6a30-40da-922e-3326bd1987da', 'pending'),
(20002, 'Urea, Electrolyte & Creatinine', '30095', 3000, '30095', '1329b5ea-7af9-41ea-8110-fc045495447e', 'pending'),
(20001, 'Full Blood Count', '2021', 2200, '2021', '1329b5ea-7af9-41ea-8110-fc045495447e', 'pending'),
(20003, 'Urinalysis', '0', 700, '4038', '1329b5ea-7af9-41ea-8110-fc045495447e', 'pending'),
(20002, 'Lipids Profile.', '30096', 3300, '30096', '1329b5ea-7af9-41ea-8110-fc045495447e', 'pending'),
(20002, 'Uric Acid', '0', 1000, '30092', '1329b5ea-7af9-41ea-8110-fc045495447e', 'pending'),
(20002, 'Albumin', '0', 1000, '300978', '1329b5ea-7af9-41ea-8110-fc045495447e', 'pending'),
(20002, 'Inorganic Phosphorus', '0', 700, '30048', '1329b5ea-7af9-41ea-8110-fc045495447e', 'pending'),
(20002, 'Calcium', '0', 800, '30027', '1329b5ea-7af9-41ea-8110-fc045495447e', 'pending'),
(20001, 'Full Blood Count', '2021', 2200, '2021', '8a68022f-7d36-4f03-bb9d-eab160b1216c', 'pending'),
(20002, 'Urea, Electrolyte & Creatinine', '30095', 3000, '30095', '8a68022f-7d36-4f03-bb9d-eab160b1216c', 'pending'),
(20003, 'MALARIA PARASITES', '0', 700, '4020', '8a68022f-7d36-4f03-bb9d-eab160b1216c', 'pending'),
(20003, 'Urinalysis', '0', 700, '4038', '8a68022f-7d36-4f03-bb9d-eab160b1216c', 'pending'),
(20001, 'ESR', '0', 1200, '2009', '8a68022f-7d36-4f03-bb9d-eab160b1216c', 'pending'),
(20002, 'Calcium', '0', 800, '30027', '8a68022f-7d36-4f03-bb9d-eab160b1216c', 'pending'),
(20003, 'Urine M/C/S', '0', 3000, '4039', '8a68022f-7d36-4f03-bb9d-eab160b1216c', 'pending'),
(20001, 'Full Blood Count', '2021', 2200, '2021', '56cfeb9b-bb3c-492b-995e-bb8c7bff65ca', 'pending'),
(20002, 'Urea, Electrolyte & Creatinine', '30095', 3000, '30095', '56cfeb9b-bb3c-492b-995e-bb8c7bff65ca', 'pending'),
(20003, 'MALARIA PARASITES', '0', 700, '4020', '56cfeb9b-bb3c-492b-995e-bb8c7bff65ca', 'pending'),
(20003, 'Urinalysis', '0', 700, '4038', '56cfeb9b-bb3c-492b-995e-bb8c7bff65ca', 'pending'),
(20001, 'Full Blood Count', '2021', 2200, '2021', '76850440-5608-4719-8ba2-5a20453193ce', 'pending'),
(20003, 'MALARIA PARASITES', '0', 700, '4020', '76850440-5608-4719-8ba2-5a20453193ce', 'pending'),
(20001, 'ESR', '0', 1200, '2009', '76850440-5608-4719-8ba2-5a20453193ce', 'pending'),
(20002, 'Calcium', '0', 800, '30027', '8d60223a-3336-495a-a36b-e35d1b904b8c', 'pending'),
(20003, 'Urinalysis', '0', 700, '4038', '63a3fd64-7aa3-4b8e-a9ad-278a3dd9a35e', 'pending'),
(20003, 'Urine M/C/S', '0', 3000, '4039', '63a3fd64-7aa3-4b8e-a9ad-278a3dd9a35e', 'pending'),
(20002, 'Calcium', '0', 800, '30027', '63a3fd64-7aa3-4b8e-a9ad-278a3dd9a35e', 'pending'),
(20002, 'C - REACTIVE PROTEIN (CRP)', '0', 6000, '3001007', '63a3fd64-7aa3-4b8e-a9ad-278a3dd9a35e', 'pending');

-- --------------------------------------------------------

--
-- Table structure for table `pending_txn`
--

CREATE TABLE `pending_txn` (
  `id` int(11) NOT NULL,
  `facilityId` varchar(50) DEFAULT NULL,
  `transaction_id` varchar(50) NOT NULL,
  `description` varchar(200) NOT NULL,
  `head` varchar(10) NOT NULL,
  `subhead` varchar(10) NOT NULL,
  `amount` int(11) NOT NULL,
  `service_type` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `patient_name` varchar(150) NOT NULL,
  `patient_id` varchar(50) NOT NULL,
  `patient_type` varchar(50) NOT NULL,
  `total_amount` int(11) NOT NULL,
  `client_acc` varchar(45) NOT NULL DEFAULT 'pending',
  `tx_status` varchar(45) NOT NULL DEFAULT 'pending',
  `transaction_date` datetime DEFAULT NULL,
  `qty_out` int(50) DEFAULT NULL,
  `selling_price` varchar(50) DEFAULT NULL,
  `cashier_id` varchar(50) DEFAULT NULL,
  `mode_of_payment` varchar(50) DEFAULT NULL,
  `request_id` varchar(50) DEFAULT NULL,
  `consultation_number` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pharm_branches`
--

CREATE TABLE `pharm_branches` (
  `id` int(11) NOT NULL,
  `branch_name` varchar(50) NOT NULL,
  `location` varchar(50) DEFAULT NULL,
  `address` varchar(100) DEFAULT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `crm` varchar(50) DEFAULT NULL,
  `created_time` timestamp NULL DEFAULT current_timestamp(),
  `facilityId` varchar(50) NOT NULL,
  `store_type` varchar(100) NOT NULL,
  `admin_name` varchar(50) NOT NULL,
  `created_by` varchar(50) NOT NULL,
  `manage_by` varchar(100) NOT NULL,
  `store_code` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pharm_branches`
--

INSERT INTO `pharm_branches` (`id`, `branch_name`, `location`, `address`, `phone`, `crm`, `created_time`, `facilityId`, `store_type`, `admin_name`, `created_by`, `manage_by`, `store_code`) VALUES
(1, 'Prime Pharmacy', 'PSC Prime', '2 Lamido Crescent , Kano', '', NULL, '2022-09-20 04:42:48', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Store', 'abdurrahman', '5', '5', '13bc4489-4807-4ad5-aa55-4b13ed697074'),
(2, 'Nursing Station', 'PSC Prime', '', '', NULL, '2022-09-21 12:01:42', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Store', 'abdurrahman', '5', '5', 'c449bdaf-413a-4c53-94ee-7743c5e4c4e5'),
(3, 'Theater Store', 'Theater', '', '', NULL, '2022-10-08 06:57:25', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Store', 'Maryam', '825', '825', 'a6631135-54bd-44d7-aff9-328d5bb5badf'),
(4, 'Laboratory Store', 'Laboratory', '', NULL, NULL, '2022-11-08 06:57:25', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Store', 'Suliaman', '825', '825', 'a6631135-54bd-44d7-aff9-32899bb5badf'),
(5, 'RECEPTION ', 'PRIME HOSPITAL', '', '', NULL, '2022-12-16 05:28:34', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Store', 'Suleiman', '11', '11', '7e25c08d-6dbe-4587-b169-637da7c304ab');

-- --------------------------------------------------------

--
-- Table structure for table `pharm_store`
--

CREATE TABLE `pharm_store` (
  `balance` int(11) DEFAULT 0,
  `drug_name` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `price` float DEFAULT NULL,
  `prefix` varchar(50) DEFAULT NULL,
  `item_code` varchar(50) NOT NULL,
  `group_code` varchar(50) DEFAULT NULL,
  `specification` varchar(50) DEFAULT NULL,
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `expired_status` varchar(50) DEFAULT 'false',
  `expiry_date` date NOT NULL DEFAULT '1111-11-11',
  `store` varchar(50) NOT NULL,
  `selling_price` float NOT NULL,
  `supplier_name` varchar(100) DEFAULT NULL,
  `supplier_code` varchar(100) DEFAULT NULL,
  `store_location` varchar(50) DEFAULT NULL,
  `generic_name` varchar(50) DEFAULT NULL,
  `insert_date` datetime DEFAULT NULL,
  `reoder_level` int(50) DEFAULT NULL,
  `uom` varchar(100) DEFAULT NULL,
  `drug_category` varchar(100) DEFAULT NULL,
  `item_id` varchar(60) DEFAULT NULL,
  `barcode` varchar(100) DEFAULT NULL,
  `grn_no` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pharm_store`
--

INSERT INTO `pharm_store` (`balance`, `drug_name`, `price`, `prefix`, `item_code`, `group_code`, `specification`, `facilityId`, `expired_status`, `expiry_date`, `store`, `selling_price`, `supplier_name`, `supplier_code`, `store_location`, `generic_name`, `insert_date`, `reoder_level`, `uom`, `drug_category`, `item_id`, `barcode`, `grn_no`) VALUES
(1681, 'Atropine inj', 1000, NULL, '232', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-05-14', 'Prime Pharmacy', 1800, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'nnn', '2025-05-07 12:59:49', 987, 'card', 'ssd', NULL, '23434', '9550'),
(370, 'Hyoscine ', 9000, NULL, '236', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-05-07', 'Prime Pharmacy', 10500, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'buscopam 20mg', '2025-05-04 14:05:56', 902, 'per annum', 'SSS', NULL, '23434', '9548'),
(136, 'pragabalin', 1200, NULL, '272', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-05-09', 'Prime Pharmacy', 1500, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'pgg', '2025-05-02 08:34:43', 10, 'card', 'PPTs', NULL, '23434', '9547'),
(472, 'Clindamycin ', 980, NULL, '302', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-05-06', 'Prime Pharmacy', 995, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'Pentazocine', '2025-04-22 13:20:05', 987, '12', 'SSS', NULL, '098', '9546'),
(0, 'devrovite toofe ', 1000, NULL, '308', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2027-02-18', 'Prime Pharmacy', 1500, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, '', '2025-02-18 12:37:14', 0, 'Tab', '', NULL, '', '9542'),
(109, 'Flagyl syr', 10000, NULL, '310', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-05-06', 'Prime Pharmacy', 10500, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'Flagyl', '2025-04-22 13:20:05', 9889, '10', 'SSS', NULL, '0987', '9546'),
(0, 'cefodaxime', 15000, NULL, '314', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-03-06', 'Prime Pharmacy', 15500, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'Isoflurane', '2025-02-27 09:37:01', 423123, 'per annum', 'ssd', NULL, '7877788', '9544'),
(190, 'cefodaxime', 20000, NULL, '314', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-04-12', 'Prime Pharmacy', 21000, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'ETTs', '2025-04-05 17:33:04', 10, 'per annum', 'SSS', NULL, '23434', '9545'),
(0, 'ETT', 400, NULL, '321', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2028-02-18', 'Prime Pharmacy', 600, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'ETT', '2025-02-18 12:47:02', 4, 'Tab', '', NULL, '', '9543'),
(419, 'Ceftazidime', 8999, NULL, '322', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-05-27', 'Prime Pharmacy', 2500, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'Ceftazidime', '2025-05-06 14:46:48', 89, 'per annum', 'SSS', NULL, '23434', '9549'),
(1000, 'Ceftazidime', 1100, NULL, '322', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-08-14', 'Prime Pharmacy', 1100, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'Ceftazidime', '2025-07-14 10:26:03', 20, 'per annum', 'SSS', NULL, '7877788', '9553'),
(500, 'Ceftazidime', 30000, NULL, '322', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-12-07', 'Prime Pharmacy', 2500, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'Ceftazidime', '2025-11-12 12:07:20', 50, 'per annum', 'SSS', NULL, '23434', '9555'),
(0, 'Ceftazidime', 300, NULL, '322', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2026-09-10', 'Prime Pharmacy', 500, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'Ceftazidime', '2024-08-10 14:27:11', 10, 'tabs', '', NULL, '', '9540'),
(0, 'Ceftazidime', 400, NULL, '322', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2026-12-12', 'Prime Pharmacy', 500, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'Ceftazidime', '2025-02-17 16:56:00', 1, 'Card', '', NULL, '', '9541'),
(40, 'Pentazocine', 500, NULL, '323', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2024-09-05', 'Prime Pharmacy', 1000, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'Pentazocine', '2024-08-10 14:27:11', 10, 'tabs', '', NULL, '', '9540'),
(1979, 'Pentazocine', 2000, NULL, '323', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-05-31', 'Prime Pharmacy', 2000, 'ALBISHIR', 'b945a2af-37bd-4965-8864-6421fe3b41ea', NULL, 'Pentazocine', '2025-05-26 08:32:07', 100, 'card', 'SSS', NULL, '23434', '9551'),
(39, 'Pentazocine', 500, NULL, '323', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2026-07-04', 'Prime Pharmacy', 1000, 'Pfizer', '2e2b599c-1fbf-4727-8965-b43b3935a592', NULL, 'Pentazocine', '2025-07-04 10:49:19', 10, 'Card', '', NULL, '', '9552'),
(50, 'Isoflurane', 800, NULL, '324', NULL, NULL, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'false', '2025-10-30', 'Prime Pharmacy', 1000, 'ALBISHIR', 'b945a2af-37bd-4965-8864-6421fe3b41ea', NULL, 'Isoflurane', '2025-10-30 13:15:55', 5, 'Card', '', NULL, '', '9554');

-- --------------------------------------------------------

--
-- Table structure for table `pharm_store_entries`
--

CREATE TABLE `pharm_store_entries` (
  `version_id` varchar(100) DEFAULT NULL,
  `receive_date` varchar(50) DEFAULT NULL,
  `drug_name` varchar(50) DEFAULT NULL,
  `id` int(11) NOT NULL,
  `po_no` varchar(50) DEFAULT NULL,
  `qty_in` varchar(50) DEFAULT NULL,
  `qty_out` varchar(50) DEFAULT NULL,
  `store_type` varchar(20) DEFAULT 'Local',
  `item_code` varchar(50) DEFAULT NULL,
  `barcode` varchar(50) DEFAULT NULL,
  `grn_no` varchar(50) DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  `unit_price` float NOT NULL DEFAULT 0,
  `cost_price` float DEFAULT NULL,
  `mark_up` varchar(50) DEFAULT NULL,
  `selling_price` varchar(100) DEFAULT NULL,
  `transfer_from` varchar(50) DEFAULT NULL,
  `transfer_to` varchar(50) DEFAULT 'Prime Pharmacy',
  `branch_name` varchar(50) DEFAULT 'Prime Pharmacy',
  `item_status` varchar(20) DEFAULT NULL,
  `inserted_time` datetime(6) DEFAULT current_timestamp(6),
  `inserted_by` varchar(50) DEFAULT NULL,
  `facilityId` varchar(50) DEFAULT NULL,
  `trn_number` varchar(50) DEFAULT NULL,
  `uniqueId` varchar(40) DEFAULT NULL,
  `drug_category` varchar(100) DEFAULT 'Local',
  `truckNo` varchar(50) DEFAULT NULL,
  `waybillNo` varchar(50) DEFAULT NULL,
  `otherInfo` varchar(100) DEFAULT NULL,
  `supplier_code` varchar(150) DEFAULT NULL,
  `supplier_name` varchar(200) DEFAULT NULL,
  `reorder_level` int(11) DEFAULT NULL,
  `sales_type` varchar(50) DEFAULT NULL,
  `userName` varchar(100) DEFAULT NULL,
  `patient_id` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pharm_store_entries`
--

INSERT INTO `pharm_store_entries` (`version_id`, `receive_date`, `drug_name`, `id`, `po_no`, `qty_in`, `qty_out`, `store_type`, `item_code`, `barcode`, `grn_no`, `expiry_date`, `unit_price`, `cost_price`, `mark_up`, `selling_price`, `transfer_from`, `transfer_to`, `branch_name`, `item_status`, `inserted_time`, `inserted_by`, `facilityId`, `trn_number`, `uniqueId`, `drug_category`, `truckNo`, `waybillNo`, `otherInfo`, `supplier_code`, `supplier_name`, `reorder_level`, `sales_type`, `userName`, `patient_id`) VALUES
('1740656686374', '2025-02-27 11:44:46', 'cefodaxime', 1, NULL, '0', '20', 'Local', '314', '', 'CASH', '2025-03-06', 0, NULL, NULL, '15500', 'Prime Pharmacy', 'pos', 'Prime Pharmacy', 'pending', '2025-02-27 11:44:46.000000', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', '', '', '', '', 'Kadiri Haruna', '', '', NULL, 'sales', '', '1'),
('1740672732449', '2025-02-27 16:12:12', 'Ceftazidime', 2, NULL, '0', '50', 'Local', '322', '', 'CASH', '2026-12-12', 0, NULL, NULL, '500', 'Prime Pharmacy', 'pos', 'Prime Pharmacy', 'pending', '2025-02-27 16:12:12.000000', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', '', '', '', '', 'Kadiri Haruna', '', '', NULL, 'sales', '', '1'),
('1740688458303', '2025-02-27 20:34:18', 'cefodaxime', 3, NULL, '0', '10', 'Local', '314', '', 'CASH', '2025-03-06', 0, NULL, NULL, '15500', 'Prime Pharmacy', 'pos', 'Prime Pharmacy', 'pending', '2025-02-27 20:34:18.000000', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', '', '', '', '', 'Jjs Jjs', '', '', NULL, 'sales', '', '3'),
('1767976068262', '2026-01-09 16:27:48', 'Pentazocine', 444, NULL, '0', '5', 'Local', '323', '', 'BILL', '2026-07-04', 0, NULL, NULL, '1000', 'Prime Pharmacy', 'pos', 'Prime Pharmacy', 'pending', '2026-01-09 16:27:48.000000', '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '', '', '', '', '', 'Walk-in customer', '', '', NULL, 'sales', '', '');

-- --------------------------------------------------------

--
-- Table structure for table `posts`
--

CREATE TABLE `posts` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `author_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `slug` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `posts`
--

INSERT INTO `posts` (`id`, `title`, `content`, `image_url`, `author_id`, `created_at`, `slug`) VALUES
(2, 'Leaping into the future: MyLikita to participate in LEAP 2023', 'We are thrilled to announce that Mylikita will be participating at LEAP 2023 event which is scheduled to hold from 6–9th of febuary 2023. As one of the leading EMR startup out of Africa we are more than delighted at the opportunity to showcase our intuitive HealthTech solution which is revolutionizing how healthcare is administered in Africa and across the globe; with renowned experts across the fields of software development as well as business development.\n\nLEAP is an acronym for Leading Entrepreneurs and Pioneers and it is an annual event that connects technology innovators and leading experts from around the world to discover new ideas, build new partnerships, and connect with inspiring mentors and investors. The event typically features activities like workshops, keynote addresses, panel discussions, and networking opportunities. At this year’s event we will be focusing on technological trends and advancements in the MedTech and Healthcare sectors in general; and we are particularly excited to connect with industry experts from the healthcare and MedTech sectors.\n\nThe MyLikita team will be present at the Startup Section, Pod T1.A37. Kindly visit our website or get in touch with any of our representatives through email at hello@mylikita.clinic if you’re interested in learning more about MyLikita and our involvement in LEAP 2023. Looking forward to seeing you at Riyadh!', 'https://miro.medium.com/v2/resize:fit:1356/format:webp/1*vJGwwpngCEXzv270Dqcq8w.png', 1, '2023-01-26 09:44:06', 'leaping-into-the-future:-mylikita-to-participate-in-leap-2023'),
(3, 'How MyLikita Implements Blockchain Using The NEAR Protocol', 'In this article we are going to elaborate further on how MyLikita utilizes the immutability of the blockchain technology to securely store vital records. The advent of sophisticated record keeping infrastructures like the blockchain, has unveiled an era of substantial progress in prospective fields of study such as finance, medicine and education. A typical field where this aforementioned invention has made significant impact is in the financial sector, aiding a purely peer-to-peer version of electronic cash (Bitcoin) which allows online payments to be sent directly from one party to another without going through any financial institution (Banks), nor requiring the identity of either of the involved parties. Likewise the development team at MyLikita aims at replicating this system to integrate immutability in how patients consultation records are created and accessed.\r\n\r\nWhy Blockchain?\r\nI bet you can’t get your mind off why MyLikita insists on storing sensitive medical records on publicly accessible blockchain protocol like NEAR, which in retrospect opposes the usual convention that requires storing information of such status in private relational or non-relational databases located on secure servers, completely abstracted from daily interactions with regular users.\r\n\r\nThe problem with these conventional means of record keeping systems are numerous, for example in the case of manually storing patients medical records in files arranged within large cabinets, offsets an array of operational hazards, like in the case of a fire incidence where thousands of irreplaceable medical records could be lost within split seconds of occurrence; another disadvantage to this prolonged approach is the case of sorting records when patients need medical attention, the process required to sort and then place these physical records in a neatly formed stack cost a lot of time; that would rather have been used in administering treatments. Although electronic record keeping system attempts to solve the problems of the previously mentioned system (manual), they do not come without considerable trade offs; I’m going to highlight some of the issues that tags along this system below:\r\n\r\nCost: With the rapidly escalating costs of maintaining database systems whether on-premise or in the cloud, governments and health insurance providers certainly welcome improved technology that could help them save money while also ensuring better patient care.\r\nAuthenticity: validating the authenticity of patients records stored on regular database system is one of the biggest challenges faced by this system, as with proper access anyone can alter the content of a record from it’s initial state.\r\nSecurity/Reliability: security and reliability of standalone databases is another factor which begs the need for a much more reliable and decentralized/distributed system as millions of vital records could be stolen in case of system attacks by hackers/infiltrators, also how this system responds in cases of crashing or general downtime, how responsive are their backups and can they quickly be put in place for use when events like this happen are reasons to consider much more reliable and attack tolerant systems like the blockchain.\r\nFrom the last section we’ve seen some of the reasons why storing records on the blockchain might be ideal for platforms of large scale, in this section we’re going to go in details how we integrate the Near protocol in achieving a much optimal solution. But before we delve further we’d like to quickly talk about the NEAR protocol.\r\n\r\nSo what is the NEAR Protocol?\r\nThe Near Protocol by official definition, is a layer 1 public blockchain network, that provides a protocol upon which blockchain developers can build decentralized applications. By so doing, NEAR essentially abstracts the need for blockchain engineers to build their own blockchain protocol from scratch which is technically impossible for small scale teams (like MyLikita) that need to integrate blockchain functionalities onto their platform.\r\n\r\nIntegrating The NEAR Protocol\r\nImplementing the NEAR Protocol on MyLikita was primarily done in three phases, at first we had to create the Smart Contract; in simple terms, the smart contract is basically an intermediary between your application and the blockchain, it defines the applications logic in the way the blockchain can process it; NEAR Protocol a couple of methods for writing smart contracts onto the NEAR network, using the RUST SDK, using the JAVASCRIPT SDK, or using the WEB assembly Sdk, you can check out how to use these libraries on this link. After successfully building and testing the smart contract, we deploy the contract’s binary (executable) onto the NEAR Network using our unique credentials. To store this records on the blockchain and still maintain their confidentiality, we have to encrypt/decrypt each record using unique encryption algorithms before they are committed. NEAR has a lot of resources on how to begin building on their network, whether you migrating an application from web2 -> web3, or you’re starting out primarily on web3; i strongly suggest you checkout their site for more concrete resources on building with the blockchain.\r\n\r\nCompanies Using The NEAR Protocol\r\nSince it’s introduction to the blockchain ecosystem, the NEAR Protocol has seen significant adoption among startups and Big tech companies alike, it offers a blazing fast and cheap means of integrating blockchain functionalities and building Dapps (decentralized application). Some of startups currently building on the NEAR protocol are:\r\n\r\nMyLikita: a platform for managing patients record and other related data in a timely, effective and seamless manner.\r\nOrderly Network: a permission-less and modular protocol that brings high throughput, low latency, low fees, tight spreads and composability for DeFi builders\r\nSweat Economy: Sweat Economy is the natural evolution of Sweatcoin.\r\nGlobal, open, and fair, SWEAT is a next generation\r\ncryptocurrency that will bring the next billion people into\r\nWeb 3.0, and make movement part of global GDP.\r\nRequest Finance: A suite of financial tools to make your life easier, crypto organizations & freelancers use Request for invoices, expenses, payroll and accounting.\r\nConnect3: Connect3 is a social engagement layer of Web3 and a next-gen decentralized social networking platform for creators and users on the Open Web.\r\nConclusion\r\nIn this article we’ve seen how and why MyLikita integrates the NEAR Protocol, and how we securely encrypt and decrypt medical records using special cryptographic encryption algorithms, as well as how this improves the efficiency, security and scalability of the MyLikita software.\r\n\r\nIn subsequent publications, we are going to discuss further on MyLikita and any coming partnerships, features or developments within the telehealth ecosystem; we kindly implore you to keep an eye on our social media pages for forthcoming articles.', 'https://miro.medium.com/v2/resize:fit:1400/format:webp/1*Ogh_bb5bGzgA7jKLqHwDPA.jpeg', 1, '2022-10-06 10:35:27', 'how-mylikita-implements-blockchain-using-the-near-protocol'),
(4, 'MyLikita receives a $10,000 grant from the NEAR Foundation.', 'We are pleased to announce our recent $10, 000 grant from the NEAR foundation to propagate digital healthcare services in Africa. MyLikita is an electronic medical record platform that enables healthcare service providers (hospitals, doctors, and medical consultants) to store, utilize, and access patients’ information seamlessly.\r\n\r\nIn as much as millions of Africans have gained access to internet services in the past decades, medical practitioners still employ the manual method of handling patients’ records, which in turn makes the process of administering treatment elongated, tiring, and error-prone as these processes are repeated per patient. Mylikita aims at extirpating the cumbersome process of managing these medical records, thereby allowing doctors and medical practitioners alike to focus on what they do best, which is administering treatments.\r\n\r\nThe grant was received from the NEAR Foundation to enable MyLikita to integrate blockchain technologies using the Near open-source blockchain protocol to propagate digital healthcare services in Africa to its next phase. “We expect the number of digitally active medical services in Africa to grow exponentially in the coming years, and we are building MyLikita to be at the forefront of this revolutionary era serving as the pace-setter for which other solutions alike, will adopt to provide top-notch telehealth services to the masses, and we appreciate the supports from the NEAR Foundation to make this a reality,” says MyLikita CEO Issa Mustapha Toyin.\r\n\r\nIn subsequent publications, we are going to elaborate in detail on how MyLikita integrates the NEAR Protocol within its system to accurately encrypt and store vital records; we implore you to kindly keep an eye on our social media pages for forthcoming articles.', 'https://miro.medium.com/v2/resize:fit:1400/format:webp/1*Ogh_bb5bGzgA7jKLqHwDPA.jpeg', 1, '2022-09-26 10:44:46', 'mylikita-receives-a-$10000-grant-from-the-near-foundation'),
(5, 'Revolutionizing Healthcare: How MyLikita is Transforming Patient Care with Technology', 'In today\'s rapidly evolving digital landscape, MyLikita stands at the forefront of healthcare innovation. Our platform seamlessly integrates cutting-edge technology with compassionate care, creating a transformative experience for both patients and providers.\r\n\r\nKey Features Driving Change:\r\n- AI-powered diagnostics that reduce wait times by 40%\r\n- Blockchain-secured patient records ensuring unprecedented data security\r\n- Telemedicine capabilities bringing specialist care to remote areas\r\n- Intuitive interface designed with both clinicians and patients in mind\r\n\r\nWe recently partnered with leading medical institutions to implement our EHR system across 50+ clinics, resulting in:\r\n✓ 30% improvement in patient satisfaction scores\r\n✓ 25% reduction in administrative costs\r\n✓ 60% faster prescription processing\r\n\r\n\"The integration of MyLikita\'s platform has fundamentally changed how we deliver care,\" says Dr. Sarah Johnson of City General Hospital. \"Our team can now focus more on patients and less on paperwork.\"\r\n\r\nAs we look to the future, we\'re excited to announce our upcoming AI-assisted treatment recommendation system, launching Q3 2024. This breakthrough will analyze patient history, current symptoms, and the latest medical research to suggest personalized treatment options.\r\n\r\nJoin us in shaping the future of healthcare technology. Stay tuned for more updates!', 'https://mylikita.com/assets/me-BMK-WeBN.jpg', 1, '2025-04-21 14:20:24', 'revolutionizing-healthcare-how-mylikita-is-transforming-patient-care');

-- --------------------------------------------------------

--
-- Table structure for table `post_categories`
--

CREATE TABLE `post_categories` (
  `post_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `prescriptionrequests`
--

CREATE TABLE `prescriptionrequests` (
  `facilityId` varchar(50) NOT NULL,
  `date` date DEFAULT NULL,
  `patient_id` varchar(11) NOT NULL,
  `dosage` varchar(10) NOT NULL,
  `drug_status` varchar(10) NOT NULL,
  `seen_by` varchar(20) NOT NULL,
  `duration` varchar(10) NOT NULL,
  `period` varchar(5) NOT NULL,
  `drug` varchar(15) NOT NULL,
  `frequency` int(5) NOT NULL,
  `drug_request_id` int(30) NOT NULL,
  `price` int(10) NOT NULL,
  `quantity_dispensed` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `previous_doc`
--

CREATE TABLE `previous_doc` (
  `id` int(11) NOT NULL,
  `patient_id` varchar(20) DEFAULT NULL,
  `file_type` varchar(50) DEFAULT NULL,
  `file_url` varchar(200) DEFAULT NULL,
  `file_date` date DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `previous_doc`
--

INSERT INTO `previous_doc` (`id`, `patient_id`, `file_type`, `file_url`, `file_date`, `created_at`) VALUES
(1, '35-1', 'Consultation', 'uploads/Screenshot 2025-07-24 at 15.50.37.png', '2025-08-11', '2025-08-11 11:53:13');

-- --------------------------------------------------------

--
-- Table structure for table `prime_old_lab`
--

CREATE TABLE `prime_old_lab` (
  `id` int(11) NOT NULL DEFAULT 0,
  `account` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `subhead` varchar(100) NOT NULL,
  `head` varchar(100) NOT NULL,
  `description` varchar(200) NOT NULL,
  `unit` varchar(100) DEFAULT NULL,
  `range_from` varchar(100) DEFAULT NULL,
  `range_to` varchar(100) DEFAULT NULL,
  `other_range` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `specimen` varchar(100) NOT NULL,
  `price` int(100) NOT NULL,
  `commission_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `percentage` int(11) NOT NULL,
  `noOfLabels` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_at` varchar(100) DEFAULT NULL,
  `facilityId` varchar(50) NOT NULL,
  `created_by` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `referrals`
--

CREATE TABLE `referrals` (
  `id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL,
  `referee` varchar(255) DEFAULT NULL,
  `refereeContact` varchar(255) DEFAULT NULL,
  `referer` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `referrals`
--

INSERT INTO `referrals` (`id`, `referee`, `refereeContact`, `referer`, `createdAt`, `updatedAt`) VALUES
('082e4afa-9f99-4175-a8a1-9dfdb1cf5ac7', '', 'issatoyin@gmail.com', '34', '2020-05-16 18:34:17', '2020-05-16 18:34:17');

-- --------------------------------------------------------

--
-- Table structure for table `repairlogs`
--

CREATE TABLE `repairlogs` (
  `facilityId` varchar(50) NOT NULL,
  `id` int(11) NOT NULL,
  `date` varchar(255) DEFAULT NULL,
  `time` varchar(255) DEFAULT NULL,
  `repaired_by` varchar(255) DEFAULT NULL,
  `nature` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `updatedAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `repairlogs`
--

INSERT INTO `repairlogs` (`facilityId`, `id`, `date`, `time`, `repaired_by`, `nature`, `createdAt`, `updatedAt`) VALUES
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 1, '2019-12-24', '12:34', 'Aminu', 'reservice', '2019-12-24 15:38:11', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 2, '2019-12-24', '23:12', 'ggggg', 'nljnkm', '2019-12-24 22:43:52', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 3, '2019-12-25', '10:12', 'fahad', 'out of oil', '2019-12-25 09:48:13', NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 4, '2019-12-25', '17:12', 'glo', 'illness', '2019-12-25 16:11:46', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `report_templates`
--

CREATE TABLE `report_templates` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `department` varchar(50) NOT NULL,
  `header` varchar(200) NOT NULL,
  `body` varchar(3000) NOT NULL,
  `facilityId` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime NOT NULL,
  `updated_by` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `report_templates`
--

INSERT INTO `report_templates` (`id`, `name`, `department`, `header`, `body`, `facilityId`, `created_at`, `created_by`, `updated_at`, `updated_by`) VALUES
(4, 'Result', 'Microbiology', 'Results', 'Lorem ipsum dolor sit amet consectetur adipisicing elit. Sunt repudiandae non sapiente provident facere, ratione praesentium molestiae reprehenderit perspiciatis deleniti fugiat accusantium quaerat autem dolore possimus harum aliquam pariatur exercitationem. Alias officia incidunt reprehenderit ut libero rem consectetur reiciendis eligendi voluptatibus facilis eaque similique iste, exercitationem suscipit fugit harum deleniti delectus amet cum architecto consequatur! Aspernatur omnis suscipit, id, officia expedita, accusantium nihil fugiat totam magnam recusandae vel itaque provident eos. Tenetur pariatur cupiditate a quasi amet reprehenderit officia minima facere voluptate quod. Eius dolorem sapiente, nobis iusto nisi commodi neque porro qui, labore asperiores ipsa ut dicta fuga aliquam nostrum, ea alias sunt recusandae facere doloremque! Explicabo voluptatem minus ullam quisquam earum, delectus fuga unde culpa ad quod placeat, et, nemo sapiente animi! Suscipit aperiam perspiciatis, recusandae inventore dolor nemo repellat nulla sit? Pariatur architecto maxime modi eos, amet doloribus aut ipsum libero autem voluptatibus quam repellendus consequatur, iure aspernatur laboriosam sapiente debitis, magni eum molestias nostrum possimus iste ex! Sapiente aspernatur dignissimos aperiam suscipit cumque facilis quia debitis placeat? Excepturi iste, quisquam temporibus blanditiis, facilis obcaecati dolorum hic voluptate impedit aspernatur qui repellat nisi nesciunt odio quos vel, provident ut similique nam eius molestiae! Consectetur animi possimus voluptatem vitae molestiae perferendis minima placeat, consequatur nisi similique aperiam consequuntur voluptate iusto voluptatum vel? Facilis blanditiis, vitae ad non deleniti aut qui exercitationem itaque expedita, quaerat obcaecati repudiandae debitis eum ex repellendus. Sit vitae illum quisquam, dolor sint veritatis quam asperiores maiores praesentium eum corrupti nesciunt, doloremque molestias cum recusandae expedita. Perferendis veritatis placeat soluta libero velit porro odit voluptates illum repellat ad aperiam dicta ab, maiores accusamus qui expedita quibusdam dolorum blanditiis minima dolor quaerat. In debitis ratione consequatur porro molestiae nisi quas, similique quo repellendus voluptatem dolor autem, consectetur ut quod asperiores distinctio tempore labore sint. Fugit error nisi et ut dolor vel quos ab assumenda eum laborum, nemo placeat consequuntur vero. Illum porro doloribus excepturi et eligendi aspernatur tempora assumenda ducimus, placeat odit nisi ab sapiente dolorum exercitationem accusamus quasi architecto repellat nihil mollitia quis neque a veniam adipisci temporibus! Possimus ut autem repellat magni animi architecto eaque aliquam, culpa distinctio debitis deleniti nam eos ducimus obcaecati et blanditiis? Voluptatem cupiditate ipsa ut eos neque natus rem sapiente sequi quae quisquam aspernatur ipsum reiciendis eius tenetur, doloribus blanditiis non nulla rerum voluptates vel nostrum ape', '966a89f6-05d8-4564-b319-2f8863821e75', '2020-09-01 01:26:18', '41', '0000-00-00 00:00:00', ''),
(5, 'Result', 'Radiology', 'Result', '<p>some design</p>\n', '966a89f6-05d8-4564-b319-2f8863821e75', '2020-09-18 03:51:47', 'admin', '0000-00-00 00:00:00', ''),
(6, 'WIDAL', 'Laboratories', 'WIDAL', '\n', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2022-10-03 10:58:25', 'Mubarak', '0000-00-00 00:00:00', '');

-- --------------------------------------------------------

--
-- Stand-in structure for view `saved_pending_request`
-- (See below for the actual view)
--
CREATE TABLE `saved_pending_request` (
`labno` varchar(100)
,`booking_no` varchar(100)
,`name` varchar(101)
,`code` varchar(50)
,`patient_id` varchar(50)
,`status` varchar(20)
,`department` varchar(30)
,`head` varchar(100)
,`test_group` varchar(20)
,`description` varchar(200)
,`subhead` varchar(100)
);

-- --------------------------------------------------------

--
-- Table structure for table `sensitivity_list`
--

CREATE TABLE `sensitivity_list` (
  `id` int(11) NOT NULL,
  `antibiotic` varchar(100) DEFAULT NULL,
  `facilityId` varchar(50) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `sensitivity_list`
--

INSERT INTO `sensitivity_list` (`id`, `antibiotic`, `facilityId`, `created_at`, `created_by`, `updated_at`, `updated_by`) VALUES
(3, 'Flucloxacillin', '966a89f6-05d8-4564-b319-2f8863821e75', '2020-08-27 00:49:34', '', '0000-00-00 00:00:00', ''),
(4, 'Tetracycline', '966a89f6-05d8-4564-b319-2f8863821e75', '2020-08-27 00:49:34', '', '0000-00-00 00:00:00', ''),
(5, 'Ampicilin', '966a89f6-05d8-4564-b319-2f8863821e75', '2020-08-27 00:49:34', '', '0000-00-00 00:00:00', ''),
(8, 'Flucloxacillin', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-03-14 03:54:32', 'abdurrahman', NULL, NULL),
(9, 'Tetracycline', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-03-14 03:54:42', 'abdurrahman', NULL, NULL),
(10, 'Ampicilin', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-03-14 03:54:50', 'abdurrahman', NULL, NULL),
(11, 'Gentamacin', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-10-26 07:03:19', 'zaks', NULL, NULL),
(12, 'Colistin sulphate', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-12-02 07:54:34', 'abdurrahman', NULL, NULL),
(13, 'Amoxycline /clavulanic acid', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-12-02 07:54:48', 'abdurrahman', NULL, NULL),
(14, 'Cefuroxime', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-12-02 07:55:05', 'abdurrahman', NULL, NULL),
(15, 'Azithromycin', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-12-02 07:55:39', 'abdurrahman', NULL, NULL),
(16, 'Doxycycline', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-12-02 07:55:53', 'abdurrahman', NULL, NULL),
(17, 'Imipenem', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-12-02 07:56:34', 'abdurrahman', NULL, NULL),
(18, 'Meropenem', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-12-02 07:56:47', 'abdurrahman', NULL, NULL),
(19, 'Clindamycin', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2021-12-02 07:57:04', 'abdurrahman', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `sensitivity_results`
--

CREATE TABLE `sensitivity_results` (
  `antibiotic` varchar(50) NOT NULL,
  `isolates` varchar(50) DEFAULT NULL,
  `R` varchar(10) NOT NULL,
  `S` varchar(10) NOT NULL,
  `I` varchar(10) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` varchar(50) NOT NULL,
  `labno` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `servicelogs`
--

CREATE TABLE `servicelogs` (
  `facilityId` varchar(50) NOT NULL,
  `id` int(11) NOT NULL,
  `date` varchar(255) DEFAULT NULL,
  `next_service_due_date` varchar(255) DEFAULT NULL,
  `createdAt` datetime DEFAULT current_timestamp(),
  `updatedAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `servicelogs`
--

INSERT INTO `servicelogs` (`facilityId`, `id`, `date`, `next_service_due_date`, `createdAt`, `updatedAt`) VALUES
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 1, NULL, '2019-12-30', '2019-12-24 00:00:00', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `facilityId` varchar(50) NOT NULL,
  `title` varchar(225) DEFAULT NULL,
  `description` varchar(225) DEFAULT NULL,
  `accHead` varchar(50) NOT NULL,
  `cost` varchar(7) DEFAULT '0',
  `service_id` int(11) NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`facilityId`, `title`, `description`, `accHead`, `cost`, `service_id`, `createdAt`) VALUES
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Staff Medical Bill', 'Companies', 'Income', '0', 23, '2019-12-21 11:39:03'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultations (Ortho, Neurosurgeon)', '', 'Income', '7000', 2, '2019-12-19 08:21:39'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Enema', '', 'Income', '5000', 3, '2019-12-19 08:23:10'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Surgery', '', 'Income', '0', 4, '2019-12-19 08:36:55'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (Regular)', '', 'Income', '3000', 6, '2019-12-20 01:58:14'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Registration (Single)', '', 'Income', '5000', 7, '2019-12-20 01:58:45'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Registration (Family)', '', 'Income', '7000', 8, '2019-12-20 01:59:09'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (Neurology)', '', 'Income', '8000', 9, '2019-12-20 01:59:49'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (Specialist) F/Up', '', 'Income', '6000', 10, '2019-12-20 02:00:41'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (Ortho, Neurosurgeon) F/Up', '', 'Income', '4000', 11, '2019-12-20 02:31:32'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (ENT)', '', 'Income', '8000', 12, '2019-12-20 02:35:19'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (Nephrology)', '', 'Income', '8000', 13, '2019-12-20 02:35:57'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (Psycharist)', '', 'Income', '8000', 14, '2019-12-20 02:36:39'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (Paediatrics)', '', 'Income', '6000', 15, '2019-12-20 02:37:07'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (Cardiology)', '', 'Income', '8000', 16, '2019-12-20 02:37:53'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Medication', 'Dispensed drugs, injection s and treatment', 'Income', '0', 24, '2019-12-22 02:08:36'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Wound Dressing (Minor)', '', 'Income', '1000', 19, '2019-12-20 02:39:05'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Wound Dressing (Major)', '', 'Income', '2000', 20, '2019-12-20 02:39:05'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'ECG', '', 'Income', '4000', 21, '2019-12-20 02:39:05'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'General Ward', '', 'Income', '7000', 25, '2019-12-22 03:15:36'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'House (White, Blue, Green)', '', 'Income', '19000', 26, '2019-12-22 03:16:59'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'PSC (0,1,2,3)', '', 'Income', '17000', 27, '2019-12-22 03:17:25'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Private (1, 2, Yellow)', '', 'Income', '12000', 28, '2019-12-22 03:17:57'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Professional Management', 'In-patient consultations', 'Income', '4000', 29, '2019-12-22 03:27:22'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Investigation', '', 'Income', '0', 30, '2019-12-22 03:50:36'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (Urology)', 'Payment before cosultation', 'Income', '8000', 31, '2019-12-22 11:17:33'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Consultation (Orthopedic)', 'Regular Orthopedic Consultation', 'Income', '7000', 32, '2019-12-23 03:52:27'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Orthopedic Registration (Family)', '', 'Income', '9000', 33, '2019-12-24 04:08:12'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Ear syringing', '', 'Income', '7000', 34, '2019-12-25 08:53:20'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Registration /Specialist Consultation (Family)', '', 'Income', '10000', 35, '2019-12-25 09:04:08'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'conversion of file', '', 'Income', '2000', 36, '2019-12-25 09:10:01'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Orthopedic Registration', '', 'Income', '7000', 37, '2019-12-25 09:13:16'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Uncology (Registration/Consultation)', '', 'Income', '8000', 38, '2019-12-26 06:00:06'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Laboratory (RBS)', '', 'Income', '500', 39, '2019-12-26 06:04:08'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Lab', '', 'Income', '0', 40, '2019-12-26 06:04:35'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Neurosurgeon (Registration)', '', 'Income', '7000', 42, '2019-12-27 06:35:36'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Urologist Registration', '', 'Income', '8000', 43, '2019-12-27 07:41:18'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Theatre fee', '', 'Income', '0', 44, '2019-12-29 05:45:01'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Implants', 'Screws and Rod', 'Income', '0', 45, '2019-12-29 05:48:29'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Nebulizer', '', 'Income', '0', 46, '2019-12-31 00:26:37'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Hospitalization Deposit', '', 'Income', '0', 47, '2020-01-01 11:16:05'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Orthopaedic F/up', 'Wages', 'Income', '4000', 48, '2020-01-02 10:47:42'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Admission', '', 'Income', '0', 49, '2020-01-03 09:29:05'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'Specialist', 'First visit', 'Income', '8000', 50, '2020-01-04 11:10:25'),
('6c6af0c0-35ea-40d8-a928-b13a9766113a', 'Wound Dressing', '', 'Consultation', '2050', 53, '2020-07-15 13:56:59'),
('6c6af0c0-35ea-40d8-a928-b13a9766113a', 'Admission', '', 'Consultation', '3000', 54, '2020-07-15 13:57:17'),
('966a89f6-05d8-4564-b319-2f8863821e75', 'Admission', '', 'Other Income', '1000', 55, '2020-08-16 01:33:44');

-- --------------------------------------------------------

--
-- Table structure for table `specimen`
--

CREATE TABLE `specimen` (
  `id` int(11) NOT NULL,
  `department` varchar(50) NOT NULL,
  `sample` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `facilityId` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `specimen`
--

INSERT INTO `specimen` (`id`, `department`, `sample`, `created_at`, `facilityId`) VALUES
(1, 'Hematology', 'Blood', '2020-10-16 01:44:33', '966a89f6-05d8-4564-b319-2f8863821e75'),
(2, 'Chemical Pathology', 'Swab', '2020-10-16 01:44:33', '966a89f6-05d8-4564-b319-2f8863821e75'),
(3, 'Hematology', 'EDTA Blood', '2020-10-16 01:44:40', '966a89f6-05d8-4564-b319-2f8863821e75'),
(4, 'Chemical Pathology', 'Serum Refrigerated', '2020-10-16 01:44:40', '966a89f6-05d8-4564-b319-2f8863821e75'),
(5, 'Hematology', 'Floride Fasting', '2020-10-16 01:50:17', '966a89f6-05d8-4564-b319-2f8863821e75'),
(6, 'Hematology', 'Urine', '2020-10-16 01:57:42', '966a89f6-05d8-4564-b319-2f8863821e75'),
(7, 'Chemical Pathology', 'Stool', '2020-10-16 01:57:42', '966a89f6-05d8-4564-b319-2f8863821e75');

-- --------------------------------------------------------

--
-- Table structure for table `staff`
--

CREATE TABLE `staff` (
  `id` int(11) NOT NULL,
  `Names` varchar(50) NOT NULL,
  `Address` varchar(100) NOT NULL,
  `role` varchar(100) NOT NULL,
  `Phone` varchar(30) NOT NULL,
  `code` varchar(10) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `suppliersinfo`
--

CREATE TABLE `suppliersinfo` (
  `facilityId` varchar(50) NOT NULL,
  `id` int(11) NOT NULL,
  `supplier_name` varchar(100) DEFAULT NULL,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  `address` varchar(250) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `code` varchar(10) DEFAULT NULL,
  `balance` int(11) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `website` varchar(100) DEFAULT NULL,
  `supplier_code` varchar(55) DEFAULT NULL,
  `tinnumber` varchar(60) DEFAULT NULL,
  `supplier_type` varchar(100) DEFAULT NULL,
  `vat` varchar(80) DEFAULT NULL,
  `email` varchar(90) DEFAULT NULL,
  `version_id` varchar(100) DEFAULT NULL,
  `other_info` varchar(80) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `suppliersinfo`
--

INSERT INTO `suppliersinfo` (`facilityId`, `id`, `supplier_name`, `date`, `address`, `phone`, `code`, `balance`, `status`, `website`, `supplier_code`, `tinnumber`, `supplier_type`, `vat`, `email`, `version_id`, `other_info`) VALUES
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 1, 'Pfizer', '2024-08-10 14:23:29', 'Kano', '', NULL, NULL, NULL, '', '2e2b599c-1fbf-4727-8965-b43b3935a592', '0', '', '0', '', '', ''),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 2, 'ALBISHIR', '2025-05-22 13:07:44', 'Nigeria, 960135', '07032151593', NULL, NULL, NULL, '', 'b945a2af-37bd-4965-8864-6421fe3b41ea', '0', '', '0', 'harunakadiri702@gmail.com', '', '');

--
-- Triggers `suppliersinfo`
--
DELIMITER $$
CREATE TRIGGER `after_supplier_edit` AFTER UPDATE ON `suppliersinfo` FOR EACH ROW BEGIN
    IF OLD.supplier_name <> new.supplier_name THEN
        INSERT INTO audit_trail(id,facilityId,	supplier_name, new_supplier_name,source_table)
        VALUES(old.id, old.facilityId, old.supplier_name,new.supplier_name,'suppliersinfo');
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `supplier_entries`
--

CREATE TABLE `supplier_entries` (
  `entry_id` int(11) NOT NULL,
  `supplier_id` varchar(50) NOT NULL,
  `dr` int(11) NOT NULL,
  `cr` int(11) NOT NULL,
  `reference_no` varchar(50) NOT NULL,
  `facilityId` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `description` varchar(60) DEFAULT NULL,
  `truckNo` varchar(50) DEFAULT NULL,
  `waybillNo` varchar(50) DEFAULT NULL,
  `version_id` varchar(50) DEFAULT NULL,
  `cost_price` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `supplier_entries`
--

INSERT INTO `supplier_entries` (`entry_id`, `supplier_id`, `dr`, `cr`, `reference_no`, `facilityId`, `created_at`, `description`, `truckNo`, `waybillNo`, `version_id`, `cost_price`, `quantity`) VALUES
(1, '2e2b599c-1fbf-4727-8965-b43b3935a592', 20000, 0, '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-08-10 14:27:11', 'Pentazocine', '', '', '', 500, 40),
(15, 'b945a2af-37bd-4965-8864-6421fe3b41ea', 4000000, 0, '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-05-26 08:32:07', 'Pentazocine', '', '', '', 2000, 2000),
(16, '2e2b599c-1fbf-4727-8965-b43b3935a592', 25000, 0, '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-07-04 10:49:19', 'Pentazocine', '', '', '', 500, 50),
(17, '2e2b599c-1fbf-4727-8965-b43b3935a592', 1100000, 0, '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-07-14 10:26:03', 'Ceftazidime', '', '', '', 1100, 1000),
(18, 'b945a2af-37bd-4965-8864-6421fe3b41ea', 40000, 0, '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-10-30 13:15:55', 'Isoflurane', '', '', '', 800, 50),
(19, '2e2b599c-1fbf-4727-8965-b43b3935a592', 15000000, 0, '', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-11-12 12:07:20', 'Ceftazidime', '', '', '', 30000, 500);

-- --------------------------------------------------------

--
-- Table structure for table `surgeons_list`
--

CREATE TABLE `surgeons_list` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `type` varchar(50) NOT NULL,
  `facilityId` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `surgeons_list`
--

INSERT INTO `surgeons_list` (`id`, `name`, `type`, `facilityId`, `created_at`, `created_by`) VALUES
(229, 'Dr. Saminu Mohammad', 'Surgeon', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2024-05-30 13:32:13', 'Manager');

-- --------------------------------------------------------

--
-- Table structure for table `surgical_note`
--

CREATE TABLE `surgical_note` (
  `id` int(11) NOT NULL,
  `patient_id` varchar(20) NOT NULL,
  `patient_name` varchar(80) NOT NULL,
  `relative` varchar(80) NOT NULL,
  `agreed` varchar(6) NOT NULL,
  `witness_by` varchar(80) NOT NULL,
  `created_by` varchar(40) NOT NULL,
  `facilityId` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `surgical_note`
--

INSERT INTO `surgical_note` (`id`, `patient_id`, `patient_name`, `relative`, `agreed`, `witness_by`, `created_by`, `facilityId`, `created_at`) VALUES
(1, '2-1', 'Sadiq Haruna', 'Husband', 'Yes', 'Muhammad Ahmad', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-03-08 02:22:14'),
(2, '15-1', 'Patient Testcece', 'Husband', 'Yes', '', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-04-25 05:07:37'),
(3, '22-1', 'Jaki Jaki', 'Husband', 'No', '', 'abdurrahman', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-05-06 04:11:18');

-- --------------------------------------------------------

--
-- Table structure for table `surgical_note_temp`
--

CREATE TABLE `surgical_note_temp` (
  `id` int(11) NOT NULL,
  `template` varchar(4567) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `facilityId` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `surgical_note_temp`
--

INSERT INTO `surgical_note_temp` (`id`, `template`, `created_at`, `facilityId`) VALUES
(0, '<h1 style=\"text-align: center;\"><strong>&nbsp;<span style=\"font-size:36px\"><span style=\"font-family:Times New Roman,Times,serif\">PRIME SPECIALIST CLINIC, KANO</span></span></strong></h1>\r\n\r\n<p style=\"text-align: center;\"><strong><span style=\"font-family:Arial,Helvetica,sans-serif\"><span style=\"font-size:16pt\">19 Lamido Crescent, off Tarauni, Kano.</span></span></strong></p>\r\n\r\n<p style=\"text-align: right;\"><strong><span style=\"font-family:Arial,Helvetica,sans-serif\"><span style=\"font-size:16pt\">RC: 1285352</span></span></strong></p>\r\n\r\n<p style=\"text-align: center;\"><strong><span style=\"font-family:Times New Roman,Times,serif\"><span style=\"font-size:22pt\">SURGICAL CONSENT </span></span></strong></p>\r\n\r\n<p>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;I am signing this document with full knowledge of its contents. I absolutely agreed for the medical team to carry out all necessary investigations concerning (my/my wife&#39;s/relative&#39;s/child&#39;s) ailment including ultrasound scanning, lumber puncture, etc. and also to carry out surgical intervention on (me/my wife/my relative and/or child).</p>\r\n\r\n<p>I understood that during surgical procedures and anesthesia, there could be unforeseeable consequences and complications.</p>\r\n\r\n<p>I know that surgical procedures carry risks of bleeding, infection, cardiac disturbance and even negative outcomes. Prior to signing this consent, I (parent/relative) had a discussion with the (doctor/ doctors) and the (doctor/doctors) explained to (me/us) about (my/ my wife&#39;s/ my relative&#39;s/ child&#39;s) health&#39;s condition and on (form/ forms) of</p>\r\n\r\n<p>Treatments; explained what exactly would be done during the surgical manipulations; informed us on the other forms of treatment for this particular ailment and the advantage of the chosen treatment.</p>\r\n\r\n<p>(1/ we) understood that in some circumstances, there could be a need for a repeat surgical procedure in which I agreed. (I/ we) know that (I am/ we are) obliged to notify the (doctor/ doctors) about all health&#39;s problems including allergic reactions prior to and during post-surgical rehabilitations periods.</p>\r\n\r\n<p>In case of blood lost, I agreed for blood transfusion to (meet my wife/ my relative/ my child). In situation of blood deficit from blood banks, (me/ us) the relatives are informed and agreed/ ready to provide blood and other medications during surgery or during post-surgical rehabilitation.</p>\r\n', '2024-01-28 14:45:05', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(1, '<h1 style=\"text-align: center;\"><strong>&nbsp;<span style=\"font-size:36px\"><span style=\"font-family:Times New Roman,Times,serif\">PRIME SPECIALIST CLINIC, KANO</span></span></strong></h1>\n\n<p style=\"text-align: center;\"><strong><span style=\"font-family:Arial,Helvetica,sans-serif\"><span style=\"font-size:16pt\">19 Lamido Crescent, off Tarauni, Kano.</span></span></strong></p>\n\n<p style=\"text-align: right;\"><strong><span style=\"font-family:Arial,Helvetica,sans-serif\"><span style=\"font-size:16pt\">RC: 1285352</span></span></strong></p>\n\n<p style=\"text-align: center;\"><strong><span style=\"font-family:Times New Roman,Times,serif\"><span style=\"font-size:22pt\">SURGICAL CONSENT </span></span></strong></p>\n\n<p>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;I am signing this document with full knowledge of its contents. I absolutely agreed for the medical team to carry out all necessary investigations concerning (my/my wife&#39;s/relative&#39;s/child&#39;s) ailment including ultrasound scanning, lumber puncture, etc. and also to carry out surgical intervention on (me/my wife/my relative and/or child).</p>\n\n<p>I understood that during surgical procedures and anesthesia, there could be unforeseeable consequences and complications.</p>\n\n<p>I know that surgical procedures carry risks of bleeding, infection, cardiac disturbance and even negative outcomes. Prior to signing this consent, I (parent/relative) had a discussion with the (doctor/ doctors) and the (doctor/doctors) explained to (me/us) about (my/ my wife&#39;s/ my relative&#39;s/ child&#39;s) health&#39;s condition and on (form/ forms) of</p>\n\n<p>Treatments; explained what exactly would be done during the surgical manipulations; informed us on the other forms of treatment for this particular ailment and the advantage of the chosen treatment.</p>\n\n<p>(1/ we) understood that in some circumstances, there could be a need for a repeat surgical procedure in which I agreed. (I/ we) know that (I am/ we are) obliged to notify the (doctor/ doctors) about all health&#39;s problems including allergic reactions prior to and during post-surgical rehabilitations periods.</p>\n\n<p>In case of blood lost, I agreed for blood transfusion to (meet my wife/ my relative/ my child). In situation of blood deficit from blood banks, (me/ us) the relatives are informed and agreed/ ready to provide blood and other medications during surgery or during post-surgical rehabilitation.</p>\n\n<p>I fully understood the above document for which (I/we) agreed and signed</p>\n\n<p>Patient&#39;s Name ...........................................................................................................................</p>\n\n<p>Name (Patient&#39;s husband/wife/child/relatives)................................................................ Date................................................................................................</p>\n\n<p>Signature &hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;&hellip;..</p>\n\n<p>WITNESS BY ME (NAME/IN FULL)</p>\n\n<p>..................................................................................................................................................................................</p>\n\n<p>DATE...............................................................................................................................</p>\n\n<p>SIGNATURE................................................................................................................</p>\n', '2022-07-04 10:39:31', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(2, '<h1 style=\"text-align: center;\"><strong>&nbsp;<span style=\"font-size:36px\"><span style=\"font-family:Times New Roman,Times,serif\">PRIME SPECIALIST CLINIC, KANO</span></span></strong></h1>\r\n\r\n<p style=\"text-align: center;\"><strong><span style=\"font-family:Arial,Helvetica,sans-serif\"><span style=\"font-size:16pt\">19 Lamido Crescent, off Tarauni, Kano.</span></span></strong></p>\r\n\r\n<p style=\"text-align: right;\"><strong><span style=\"font-family:Arial,Helvetica,sans-serif\"><span style=\"font-size:16pt\">RC: 1285352</span></span></strong></p>\r\n\r\n<p style=\"text-align: center;\"><strong><span style=\"font-family:Times New Roman,Times,serif\"><span style=\"font-size:22pt\">SURGICAL CONSENT </span></span></strong></p>\r\n\r\n<p>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;I am signing this document with full knowledge of its contents. I absolutely agreed for the medical team to carry out all necessary investigations concerning (my/my wife&#39;s/relative&#39;s/child&#39;s) ailment including ultrasound scanning, lumber puncture, etc. and also to carry out surgical intervention on (me/my wife/my relative and/or child).</p>\r\n\r\n<p>I understood that during surgical procedures and anesthesia, there could be unforeseeable consequences and complications.</p>\r\n\r\n<p>I know that surgical procedures carry risks of bleeding, infection, cardiac disturbance and even negative outcomes. Prior to signing this consent, I (parent/relative) had a discussion with the (doctor/ doctors) and the (doctor/doctors) explained to (me/us) about (my/ my wife&#39;s/ my relative&#39;s/ child&#39;s) health&#39;s condition and on (form/ forms) of</p>\r\n\r\n<p>Treatments; explained what exactly would be done during the surgical manipulations; informed us on the other forms of treatment for this particular ailment and the advantage of the chosen treatment.</p>\r\n\r\n<p>(1/ we) understood that in some circumstances, there could be a need for a repeat surgical procedure in which I agreed. (I/ we) know that (I am/ we are) obliged to notify the (doctor/ doctors) about all health&#39;s problems including allergic reactions prior to and during post-surgical rehabilitations periods.</p>\r\n\r\n<p>In case of blood lost, I agreed for blood transfusion to (meet my wife/ my relative/ my child). In situation of blood deficit from blood banks, (me/ us) the relatives are informed and agreed/ ready to provide blood and other medications during surgery or during post-surgical rehabilitation.</p>\r\n', '2022-07-05 19:18:33', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `test`
--

CREATE TABLE `test` (
  `id` int(11) NOT NULL,
  `description` varchar(50) NOT NULL,
  `debit` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL,
  `credit` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `test1`
-- (See below for the actual view)
--
CREATE TABLE `test1` (
`head` varchar(100)
,`subhead` varchar(50)
,`des` varchar(500)
,`acct` varchar(100)
,`debit` int(50)
,`credit` int(50)
,`description` varchar(225)
,`facilityId` varchar(50)
,`createdAt` date
,`transaction_date` date
,`transaction_id` int(11)
,`enteredBy` varchar(20)
,`receiptDateSN` varchar(50)
,`receiptNo` varchar(50)
,`modeOfPayment` varchar(50)
,`status` varchar(30)
,`approvedBy` varchar(20)
,`paymentStatus` varchar(11)
,`client_acct` varchar(200)
,`patient_id` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `facilityId` varchar(50) DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `transaction_id` int(11) NOT NULL,
  `transaction_date` date DEFAULT NULL,
  `description` varchar(225) DEFAULT NULL,
  `acct` varchar(100) DEFAULT NULL,
  `debit` int(50) DEFAULT NULL,
  `credit` int(50) DEFAULT NULL,
  `unit_price` double NOT NULL DEFAULT 0,
  `enteredBy` varchar(20) DEFAULT NULL,
  `receiptDateSN` varchar(50) NOT NULL DEFAULT '0',
  `receiptNo` varchar(50) DEFAULT NULL,
  `modeOfPayment` varchar(50) DEFAULT NULL,
  `bank_name` varchar(50) DEFAULT NULL,
  `status` varchar(30) DEFAULT 'pending',
  `approvedBy` varchar(20) DEFAULT NULL,
  `paymentStatus` varchar(11) NOT NULL DEFAULT '',
  `client_acct` varchar(200) DEFAULT NULL,
  `patient_id` varchar(50) DEFAULT NULL,
  `qty` varchar(20) DEFAULT NULL,
  `branch_name` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`facilityId`, `createdAt`, `transaction_id`, `transaction_date`, `description`, `acct`, `debit`, `credit`, `unit_price`, `enteredBy`, `receiptDateSN`, `receiptNo`, `modeOfPayment`, `bank_name`, `status`, `approvedBy`, `paymentStatus`, `client_acct`, `patient_id`, `qty`, `branch_name`) VALUES
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-02-27 12:33:00', 1, NULL, 'Deposit from account 1', '400022', 0, 0, 0, '', '250227123300', '250227123300', '', '', 'pending', NULL, '', '1', '1', NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-02-27 12:33:00', 2, NULL, 'Deposit from account 1', '400023', 0, 0, 0, '', '250227123300', '250227123300', '', '', 'pending', NULL, '', '1', '1', NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-02-27 12:33:26', 3, NULL, 'Deposit from account 2', '400022', 0, 0, 0, '', '250227123326', '250227123326', '', '', 'pending', NULL, '', '2', '2', NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-02-27 12:33:26', 4, NULL, 'Deposit from account 2', '500021', 0, 0, 0, '', '250227123326', '250227123326', '', '', 'pending', NULL, '', '2', '2', NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-02-27 11:44:11', 5, '2025-02-27', 'Laboratory: Splits (Vdrc)', '20001', 0, 250, 0, 'abdurrahman', '250227123300', '250227123300', 'CASH', '', 'paid', 'abdurrahman', 'completed', '1', '1-1', '1', 'Main Branch'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-02-27 11:44:11', 6, '2025-02-27', 'Laboratory: Splits (Vdrc)', '400021', 250, 0, 0, 'abdurrahman', '250227123300', '250227123300', 'CASH', '', 'paid', 'abdurrahman', 'completed', '1', '1-1', '1', 'Main Branch'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-02-27 11:44:20', 7, '2025-02-27', 'Surgery: Hydrocelectomy - Small', '20006', 0, 10000, 0, 'abdurrahman', '250227123326', '250227123326', 'POS', '', 'paid', 'abdurrahman', 'completed', '2', '2-1', '1', 'Main Branch'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2025-02-27 11:44:20', 8, '2025-02-27', 'Surgery: Hydrocelectomy - Small', '400022', 10000, 0, 0, 'abdurrahman', '250227123326', '250227123326', 'POS', '', 'paid', 'abdurrahman', 'completed', '2', '2-1', '1', 'Main Branch'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:04:53', 2853, '2026-01-09', 'Registration ( Family )', '20002', 0, 10000, 0, 'abdurrahman', '260109170443', '260109170443', 'CASH', '', 'paid', 'abdurrahman', 'completed', '3', '3-1', '1', 'Main Branch'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:04:53', 2854, '2026-01-09', 'Registration ( Family )', '400021', 10000, 0, 0, 'abdurrahman', '260109170443', '260109170443', 'CASH', '', 'paid', 'abdurrahman', 'completed', '3', '3-1', '1', 'Main Branch'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:09:41', 2855, '2026-01-09', 'Regular Consultation', '20003', 0, 6000, 0, 'abdurrahman', '20260109050933', '20260109050933', 'CASH', '', 'paid', 'abdurrahman', 'completed', '1', '1-1', '1', 'Main Branch'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:09:41', 2856, '2026-01-09', 'Regular Consultation', '400021', 6000, 0, 0, 'abdurrahman', '20260109050933', '20260109050933', 'CASH', '', 'paid', 'abdurrahman', 'completed', '1', '1-1', '1', 'Main Branch'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 05:11:52', 2857, NULL, 'Deposit from account 4', '400022', 0, 0, 0, '', '260109171152', '260109171152', '', '', 'pending', NULL, '', '4', '4', NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 05:11:52', 2858, NULL, 'Deposit from account 4', '500021', 0, 0, 0, '', '260109171152', '260109171152', '', '', 'pending', NULL, '', '4', '4', NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:12:23', 2859, '2026-01-09', 'Registration ( Single )', '20001', 0, 7000, 0, 'abdurrahman', '260109171152', '260109171152', 'CASH', '', 'paid', 'abdurrahman', 'completed', '4', '4-1', '1', 'Main Branch'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:12:23', 2860, '2026-01-09', 'Registration ( Single )', '400021', 7000, 0, 0, 'abdurrahman', '260109171152', '260109171152', 'CASH', '', 'paid', 'abdurrahman', 'completed', '4', '4-1', '1', 'Main Branch'),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:27:48', 2861, '2026-01-09', 'Pentazocine', '20025', 0, 5000, 1000, '', '260109172748', '260109172748', 'BILL', '', 'copleted', NULL, '', '', '', '5', ''),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:33:01', 2862, '2026-01-09', 'Chemotherapy Session', '20026', 0, 15000, 0, 'abdurrahman', '260109173214', '260109173214', 'deposit', '', 'completed', 'abdurrahman', 'completed', '2', '2-1', '1', ''),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 16:33:01', 2863, '2026-01-09', 'Chemotherapy Session', '400022', 15000, 0, 0, 'abdurrahman', '260109173214', '260109173214', 'deposit', '', 'completed', 'abdurrahman', 'completed', '2', '2-1', '1', ''),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 05:34:41', 2864, '2026-01-09', 'Payment for bill', '400025', 0, 3000, 0, 'abdurrahman', '260109173344', '260109173344', 'Cash', NULL, 'pending', NULL, '', 'Sadiq', NULL, NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 05:34:41', 2865, '2026-01-09', 'Payment for bill', '300022', 3000, 0, 0, 'abdurrahman', '260109173344', '260109173344', 'Cash', NULL, 'pending', NULL, '', 'Sadiq', NULL, NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 00:00:00', 2866, NULL, 'Deposit from account 1', '400021', 1000000, 0, 0, 'abdurrahman', '0901262601091733452866', '260109173345', 'cash', '', 'pending', NULL, '', '1', '1', NULL, NULL),
('1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2026-01-09 00:00:00', 2867, NULL, 'Deposit from account 1', '400023', 0, 1000000, 0, 'abdurrahman', '0901262601091733452866', '260109173345', 'cash', '', 'pending', NULL, '', '1', '1', NULL, NULL);

--
-- Triggers `transactions`
--
DELIMITER $$
CREATE TRIGGER `set_txn_date` BEFORE INSERT ON `transactions` FOR EACH ROW BEGIN
    		IF (isnull(new.createdAt)) THEN
    			SET NEW.createdAt=CURDATE();
            END IF;
        END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `transactions3`
--

CREATE TABLE `transactions3` (
  `facilityId` varchar(50) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `transaction_id` int(11) NOT NULL,
  `transaction_date` date DEFAULT NULL,
  `id` int(11) NOT NULL,
  `description` varchar(225) DEFAULT NULL,
  `acct` varchar(100) DEFAULT NULL,
  `acct_name` varchar(300) NOT NULL,
  `debit` int(50) DEFAULT NULL,
  `credit` int(50) DEFAULT NULL,
  `enteredBy` varchar(20) DEFAULT NULL,
  `receiptDateSN` varchar(18) NOT NULL DEFAULT '0',
  `receiptNo` int(7) DEFAULT 0,
  `modeOfPayment` varchar(15) DEFAULT NULL,
  `bank_name` varchar(50) NOT NULL,
  `status` varchar(50) DEFAULT 'Pending Lab',
  `approvedBy` varchar(20) DEFAULT NULL,
  `paymentStatus` varchar(11) NOT NULL DEFAULT '',
  `client_acct` varchar(11) DEFAULT NULL,
  `patient_id` varchar(50) NOT NULL,
  `settlement_status` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transactionsetup`
--

CREATE TABLE `transactionsetup` (
  `id` int(11) NOT NULL,
  `title` varchar(50) NOT NULL,
  `debit` varchar(50) NOT NULL,
  `credit` varchar(50) NOT NULL,
  `facilityId` varchar(50) NOT NULL,
  `createdBy` varchar(50) NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `transactionsetup`
--

INSERT INTO `transactionsetup` (`id`, `title`, `debit`, `credit`, `facilityId`, `createdBy`, `createdAt`) VALUES
(8, 'Payment from somewhere else', 'Hematology', 'Trade Payable', '966a89f6-05d8-4564-b319-2f8863821e75', '41', '2020-08-15 05:03:14'),
(9, '', 'Revenue', 'Cash', '6c6af0c0-35ea-40d8-a928-b13a9766113a', '40', '2020-08-17 00:13:26'),
(10, '', 'Registration & Testing fees', 'Cash', '966a89f6-05d8-4564-b319-2f8863821e75', '41', '2020-08-28 02:36:52');

-- --------------------------------------------------------

--
-- Table structure for table `transaction_backup`
--

CREATE TABLE `transaction_backup` (
  `facilityId` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `transaction_id` int(11) NOT NULL DEFAULT 0,
  `id` int(11) NOT NULL,
  `description` varchar(225) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `acct` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `debit` int(50) DEFAULT NULL,
  `credit` int(50) DEFAULT NULL,
  `enteredBy` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `receiptDateSN` varchar(18) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '0',
  `receiptNo` int(7) DEFAULT 0,
  `modeOfPayment` varchar(15) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `status` varchar(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT 'pending',
  `approvedBy` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `paymentStatus` varchar(11) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `client_acct` varchar(11) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `patient_id` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transaction_entries`
--

CREATE TABLE `transaction_entries` (
  `id` int(11) NOT NULL,
  `transaction_date` date NOT NULL,
  `patient_id` varchar(20) NOT NULL,
  `patient_name` varchar(200) NOT NULL,
  `receivable_head` varchar(20) NOT NULL,
  `receivable_head_name` varchar(100) NOT NULL,
  `total_amount` int(11) NOT NULL,
  `amount_paid` int(11) NOT NULL,
  `balance` int(11) NOT NULL,
  `receiptNo` varchar(50) NOT NULL,
  `entries_status` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `transaction_view`
-- (See below for the actual view)
--
CREATE TABLE `transaction_view` (
`facilityId` varchar(50)
,`createdAt` date
,`acct` varchar(100)
,`debit` int(50)
,`description` varchar(225)
,`patient_id` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `transaction_view2`
-- (See below for the actual view)
--
CREATE TABLE `transaction_view2` (
`date` timestamp
,`drug` varchar(20)
,`quantity` int(11)
,`price` int(10)
,`profit` bigint(21)
,`amount` bigint(22)
,`facilityId` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `transfers`
--

CREATE TABLE `transfers` (
  `id` int(11) NOT NULL,
  `facilityId` varchar(50) DEFAULT NULL,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  `amountReceived` int(12) NOT NULL DEFAULT 0,
  `amountHandedOver` int(12) DEFAULT 0,
  `transfer_from` varchar(50) NOT NULL,
  `transfer_to` varchar(50) NOT NULL,
  `status` varchar(10) NOT NULL DEFAULT 'pending',
  `comment` varchar(500) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `transfers`
--

INSERT INTO `transfers` (`id`, `facilityId`, `date`, `amountReceived`, `amountHandedOver`, `transfer_from`, `transfer_to`, `status`, `comment`) VALUES
(1, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-03 08:49:08', 0, 4000, 'Manager', 'Kemi', 'pending', '02-02-2020 / cash in'),
(2, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-05 09:54:39', 0, 129200, 'Patience', 'Manager', 'pending', 'Yesterday\'s day cash'),
(3, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-05 09:55:57', 0, 75200, 'Manager', 'Patience', 'pending', 'Today cash'),
(4, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-02-16 09:38:19', 0, 62000, 'Kemi', 'Manager', 'pending', '15-02 CASH IN'),
(5, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-03-14 14:50:51', 0, 50000, 'Manager', 'Kemi', 'pending', 'test'),
(6, '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', '2020-03-14 14:51:20', 0, 30000, 'Manager', 'abdurrahman', 'pending', 'netest'),
(7, 'b8823207-58e1-438c-bb62-f3c6c16d8d3d', '2020-03-19 14:51:59', 0, 1, 'isahboy01', 'isahboy01', 'pending', '');

-- --------------------------------------------------------

--
-- Stand-in structure for view `trialbalance`
-- (See below for the actual view)
--
CREATE TABLE `trialbalance` (
`head` varchar(100)
,`subhead` varchar(50)
,`des` varchar(500)
,`acct` varchar(100)
,`description` varchar(500)
,`debit` decimal(65,0)
,`credit` decimal(65,0)
,`createdAt` date
,`date` date
,`facilityId` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `trial_balance`
-- (See below for the actual view)
--
CREATE TABLE `trial_balance` (
`acct` varchar(100)
,`narration` varchar(225)
,`Acct_source` varchar(500)
,`parent_account` varchar(500)
,`debit` int(50)
,`credit` int(50)
,`facilityId` varchar(50)
,`createdAt` date
,`created_at` date
,`enteredBy` varchar(20)
,`receiptDateSN` varchar(50)
,`receiptNo` varchar(50)
,`modeOfPayment` varchar(50)
,`client_acct` varchar(200)
);

-- --------------------------------------------------------

--
-- Table structure for table `t_patientr`
--

CREATE TABLE `t_patientr` (
  `cc` bigint(21) NOT NULL,
  `id` varchar(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `firstname` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `surname` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `other` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `t_patientr`
--

INSERT INTO `t_patientr` (`cc`, `id`, `firstname`, `surname`, `other`) VALUES
(15, '-', 'Fatima', 'Suleman', ''),
(2, '1-1', 'Musa', 'Ibrahim', ''),
(2, '2-1', 'Hassan', 'Ismail', ''),
(2, '2551-15', 'Hua', 'Ding', 'Li'),
(2, '299-8', 'Abubakar', 'Amina', ''),
(2, '30-1', 'Usman', 'Mai Aliyu', 'Mai'),
(2, '3004-1', 'Mukhtar', 'Muhammad', ''),
(2, '314-12', 'Abdullahi', 'Hafsat', ''),
(2, '3151-1', 'Hafsat', 'Sabiu', ''),
(2, '4060-1', 'Idris', 'Asmau', 'undefined'),
(2, '4160-1', 'Godwin', 'Ogwuche', ''),
(4, '4347-1', 'Wonah', 'Abraham', 'undefined'),
(2, '4473-1', 'Hani', 'Okan', 'undefined'),
(2, '45-6', 'Adnan', 'Muhammad', ''),
(2, '4685-1', 'Jamilu', 'Yakudima', ''),
(2, '4691-1', 'Mariya', 'Abubakar', ''),
(2, '4708-1', 'Payment', 'Instant', NULL),
(2, '5184-1', 'RUFAI', 'GARBA', ''),
(2, '5312-1', 'Justice Nura', 'Sagir Umar', ''),
(2, '5479-1', 'Saudah', 'Ismail', ''),
(2, '5781-1', 'Mukaddas', 'Babangida', ''),
(2, '6198-1', 'Samadi', 'Aya', NULL),
(2, '6279-1', 'Musa', 'Sani', ''),
(2, '6330-1', 'Lawal', 'Umar', ''),
(2, '6356-4', 'Shehu', 'Hadiza', ''),
(2, '6608-1', 'Mustapha', '', NULL),
(2, '96-17', 'Ahmad', 'Ali', 'Sadi'),
(6, 'undefined', 'undefined', 'undefined', 'undefined');

-- --------------------------------------------------------

--
-- Table structure for table `User Departments`
--

CREATE TABLE `User Departments` (
  `id` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `department_id` int(11) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `firstname` varchar(255) DEFAULT NULL,
  `lastname` varchar(255) DEFAULT NULL,
  `privilege` int(11) DEFAULT 4,
  `role` varchar(255) DEFAULT NULL,
  `speciality` varchar(50) DEFAULT NULL,
  `accessTo` varchar(255) DEFAULT NULL,
  `functionalities` varchar(2000) DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `prefix` varchar(50) DEFAULT NULL,
  `userType` varchar(10) DEFAULT NULL,
  `serviceCost` varchar(10) DEFAULT NULL,
  `licenceNo` varchar(50) DEFAULT NULL,
  `placeOfWork` varchar(100) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `loggedIn` varchar(200) DEFAULT NULL,
  `availableDays` varchar(200) DEFAULT NULL,
  `availableFromTime` varchar(20) DEFAULT NULL,
  `availableToTime` varchar(20) DEFAULT NULL,
  `address` varchar(200) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `paymentMethod` varchar(50) DEFAULT NULL,
  `paymentAmount` int(11) DEFAULT NULL,
  `referralId` varchar(50) DEFAULT NULL,
  `lastLogin` varchar(20) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  `facilityId` varchar(50) NOT NULL,
  `createdBy` varchar(50) DEFAULT NULL,
  `department` varchar(50) DEFAULT NULL,
  `functionality` varchar(2000) DEFAULT NULL,
  `branch_name` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `firstname`, `lastname`, `privilege`, `role`, `speciality`, `accessTo`, `functionalities`, `username`, `email`, `prefix`, `userType`, `serviceCost`, `licenceNo`, `placeOfWork`, `password`, `status`, `loggedIn`, `availableDays`, `availableFromTime`, `availableToTime`, `address`, `phone`, `paymentMethod`, `paymentAmount`, `referralId`, `lastLogin`, `image`, `createdAt`, `updatedAt`, `facilityId`, `createdBy`, `department`, `functionality`, `branch_name`) VALUES
(1, 'sadiq', 'haruna', 8, 'Doctor', 'Surgery', 'Records,Accounts,Admin,Doctors,Theater,Laboratory,Reports,Pharmacy,Nurse', '', 'Sadiq', 'sadiq@gmail.com', NULL, 'admin', '5000', NULL, NULL, '$2a$10$mPqL/ehjm7v5UIy0pG9FFeWa1vfzfWo05.KyYHn/L3hmjoF8yM0vS', 'approved ', NULL, NULL, NULL, NULL, 'Kano', '07062942291', NULL, NULL, NULL, NULL, 'https://res.cloudinary.com/emaitee/image/upload/v1593618169/mylikita/profile_images/docAvater.png', '2019-10-11 19:08:28', '2025-08-11 11:25:24', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, NULL, 'Add New Patient,Bed Allocation,Hospital Billings,Create a Client Account,Make Deposit,Record Expenses,Generate Account Report,Account Statement,Asset Register,Rent Register,Create/Edit Services,Setup Account Chart,Cash Handover,Create User,Manage Users,Settings,Patient List,Appointments,Consultations,Lab Results,Video Chat,Add New Account Note,Setup Lab Test,Registrations,Report Summary,Inventory Overview,Analytics,Daily Sales,Profit,Suppliers Overview,Drug Sales,Drug Dispensary,Store Record,Returned Drugs,Manage Suppliers,Drug List,Sample Analysis,Account Review,Drug Schedule,Nursing Report,In-Patient Vitals,In-Patients,Out-Patient Prescriptions,Nursing Requests,Opening Balance,Other Incomes,Discount Setup,Pending Discount Requests,Purchase Record,Bookings,Messages,Integration', NULL),
(2, 'Sam', 'Pius', 8, 'Developer', NULL, 'Records,Doctors,Account,Pharmacy,Lab,Admin,Operation,Theater,Maintenance,Nurse', '', 'sammie', 'samsonpius@gmail.com', NULL, NULL, NULL, NULL, NULL, '$2a$10$9PVSwNYnpnc0I9MGzV5VeeLqqrM1oNH9B/uvqc9F28/0msIUIH9MW', 'approved', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, 'https://res.cloudinary.com/emaitee/image/upload/v1593618169/mylikita/profile_images/docAvater.png', '2019-12-02 18:05:19', '2019-12-02 18:05:19', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, NULL, NULL, NULL),
(3, 'Isah', 'Muhd', 4, 'Developer', NULL, 'Records,Doctors,Account,Pharmacy,Lab,Admin,Operation,Theater,Maintenance,Nurse', '', 'isahboy', 'isahboy@gmail.com', NULL, NULL, NULL, NULL, NULL, '$2a$10$c4ST/4CkMe0/emlRNcelmuJiQH1ExriJJ1P0lZvqjpxTRbDpyn2tC', 'approved', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, 'https://res.cloudinary.com/emaitee/image/upload/v1593618169/mylikita/profile_images/docAvater.png', '2019-12-02 18:40:13', '2019-12-02 18:40:13', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', NULL, NULL, NULL, NULL),
(875, 'frank', 'edward', 4, 'Manager', '', 'Laboratory,Reports,Inventory,Nurse,Pharmacy,Records,Admin,Accounts', NULL, 'edward', 'frank@gmailcom', NULL, NULL, NULL, NULL, NULL, '$2a$10$Rr489GWfIDeeGVPz2h9Zg.0jsfP79kG2S4vGOqv5IfiP.3FmJKt4G', 'approved ', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'https://res.cloudinary.com/emaitee/image/upload/v1593618169/mylikita/profile_images/docAvater.png', '2025-08-11 09:48:52', '2025-08-11 09:49:47', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'abdurrahman', '', 'Dashboard,Report Summary,GRN,Store Management,Requisition,Manage Suppliers,In-Patient Vitals,Drug Sales,Bed Allocation,Create User,Manage Users,Patients List,Other Incomes', NULL),
(876, 'small', 'small', 4, 'Doctor', 'General', 'Laboratory,Doctor,Records', NULL, 'small', 'small@gmail.com', NULL, NULL, NULL, NULL, NULL, '$2a$10$H.TxZfTZrGbxL4NRq9iuY.3yne0BUfA6N4XLM6bApvR21daeaqjp.', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'https://res.cloudinary.com/emaitee/image/upload/v1593618169/mylikita/profile_images/docAvater.png', '2025-09-08 09:11:23', '2025-09-08 09:11:23', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'abdurrahman', NULL, 'Patient List,Appointments,Consultations,Lab Results,Video Chat,Add New Patient,Bed Allocation,Dashboard,Setup Lab Test', NULL),
(877, 'sadman', 'man', 4, 'Doctor', 'General', 'Doctor', NULL, 'sadman', 'sadman@gmail.com', NULL, NULL, NULL, NULL, NULL, '$2a$10$ab4bqT1DAVbrTpCizBxKreD5o6FBrotHJ66l4cD1wwey0gPyk3qQW', 'suspended', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'https://res.cloudinary.com/emaitee/image/upload/v1593618169/mylikita/profile_images/docAvater.png', '2025-11-17 10:06:21', '2025-11-22 08:19:42', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a', 'abdurrahman', NULL, 'Patient List,Appointments,Consultations,Lab Results,Video Chat', NULL);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_all_bed_allocations`
-- (See below for the actual view)
--
CREATE TABLE `view_all_bed_allocations` (
`allocation_id` int(11)
,`bed_id` int(11)
,`ended` timestamp
,`allocated_by` varchar(50)
,`ended_by` varchar(50)
,`allocation_status` varchar(20)
,`created_at` timestamp
,`patient_name` varchar(101)
,`patient_id` varchar(50)
,`accountNo` int(7)
,`facilityId` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `vital_signs`
--

CREATE TABLE `vital_signs` (
  `id` int(11) NOT NULL,
  `patient_id` varchar(50) NOT NULL,
  `body_temp` varchar(5) DEFAULT NULL,
  `pulse_rate` varchar(10) DEFAULT NULL,
  `blood_pressure` varchar(10) DEFAULT NULL,
  `respiratory_rate` varchar(10) DEFAULT NULL,
  `fasting_blood_sugar` varchar(10) DEFAULT NULL,
  `random_blood_sugar` varchar(10) DEFAULT NULL,
  `spo2` varchar(50) DEFAULT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `facilityId` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `vital_signs`
--

INSERT INTO `vital_signs` (`id`, `patient_id`, `body_temp`, `pulse_rate`, `blood_pressure`, `respiratory_rate`, `fasting_blood_sugar`, `random_blood_sugar`, `spo2`, `created_by`, `created_at`, `facilityId`) VALUES
(1, '1-1', '35', '123', '434', '23', '212', '12', '30', 'abdurrahman', '2024-08-10 03:08:22', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(2, '6-1', 'B2', '56', '67', '89', '67', '23', '55', 'abdurrahman', '2025-03-08 02:29:10', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(3, '1-55', '12', '90', '12', '77', '12', '77', '10', 'abdurrahman', '2025-07-04 11:44:06', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(4, '21-1', 'B2', '56', '67', '89', '67', '23', '55', 'abdurrahman', '2025-08-01 03:57:32', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a'),
(5, '35-1', 'B2', '2', '22', '89', '22', '22', '55', 'abdurrahman', '2025-08-05 10:16:29', '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a');

-- --------------------------------------------------------

--
-- Table structure for table `voucher`
--

CREATE TABLE `voucher` (
  `vo_No` int(11) NOT NULL,
  `debit` varchar(40) NOT NULL,
  `Amount` int(11) NOT NULL,
  `credit` varchar(40) NOT NULL,
  `description` varchar(50) NOT NULL,
  `authorizedby` varchar(40) NOT NULL,
  `approveBy` varchar(40) NOT NULL,
  `PatientAcct` varchar(20) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `wholesale_transaction`
--

CREATE TABLE `wholesale_transaction` (
  `id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL,
  `date` varchar(100) NOT NULL,
  `time` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `phone_no` varchar(50) DEFAULT NULL,
  `unit` int(11) DEFAULT NULL,
  `amount` varchar(50) NOT NULL,
  `type` varchar(20) NOT NULL,
  `giver` varchar(100) DEFAULT NULL,
  `reciever` varchar(100) DEFAULT NULL,
  `description` varchar(100) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Structure for view `account_head`
--
DROP TABLE IF EXISTS `account_head`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `account_head`  AS SELECT `a`.`head` AS `head`, `a`.`subhead` AS `subhead`, `a`.`description` AS `description`, `b`.`description` AS `des` FROM (`account` `a` join `account` `b` on(`a`.`head` = `b`.`subhead`)) ;

-- --------------------------------------------------------

--
-- Structure for view `bedlist_view`
--
DROP TABLE IF EXISTS `bedlist_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bedlist_view`  AS SELECT `bedlist`.`id` AS `id`, `bedlist`.`sort_index` AS `sort_index`, `bedlist`.`class_type` AS `class_type`, `bedlist`.`price` AS `price`, `bedlist`.`name` AS `name`, `bedlist`.`status` AS `status`, `bedlist`.`no_of_beds` AS `no_of_beds`, ifnull((select count(`bed_allocation`.`bed_id`) from `bed_allocation` where `bed_allocation`.`bed_id` = `bedlist`.`id` and `bed_allocation`.`facilityId` = `bedlist`.`facilityId` and `bed_allocation`.`ended` is null group by `bed_allocation`.`bed_id`),0) AS `occupied`, `bedlist`.`facilityId` AS `facilityId` FROM `bedlist` ;

-- --------------------------------------------------------

--
-- Structure for view `drug_schedule_view`
--
DROP TABLE IF EXISTS `drug_schedule_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `drug_schedule_view`  AS SELECT `a`.`drug` AS `drug`, `a`.`dosage` AS `dosage`, `a`.`patient_id` AS `patient_id`, `a`.`created_at` AS `created_at`, `b`.`id` AS `id`, `a`.`id` AS `prescription_id`, `a`.`prescribed_by` AS `prescribed_by`, `a`.`duration` AS `duration`, `a`.`period` AS `period`, `a`.`frequency` AS `frequency`, `a`.`route` AS `route`, `b`.`time_stamp` AS `time_stamp`, `b`.`administered_by` AS `administered_by`, `b`.`served_by` AS `served_by`, `b`.`reason` AS `reason`, `b`.`status` AS `status`, `a`.`facilityId` AS `facilityId` FROM (`dispensary` `a` join `drug_schedule` `b` on(`a`.`id` = `b`.`prescription_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `expenditure_view`
--
DROP TABLE IF EXISTS `expenditure_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `expenditure_view`  AS SELECT `a`.`subhead` AS `subhead`, `b`.`description` AS `description`, `b`.`modeOfPayment` AS `modeOfPayment`, `b`.`acct` AS `acct`, `b`.`createdAt` AS `createdAt`, `b`.`debit` AS `amount`, `b`.`facilityId` AS `facilityId`, `b`.`client_acct` AS `client_acct`, `b`.`enteredBy` AS `enteredBy` FROM (`account` `a` join `transactions` `b`) WHERE `a`.`head` = `b`.`acct` AND `a`.`subhead` = 'Expenditure' ;

-- --------------------------------------------------------

--
-- Structure for view `in_patient_list`
--
DROP TABLE IF EXISTS `in_patient_list`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `in_patient_list`  AS SELECT `b`.`sort_index` AS `sort_index`, `a`.`bed_id` AS `bed_id`, `a`.`allocation_id` AS `allocation_id`, `a`.`allocation_status` AS `allocation_status`, `a`.`allocated` AS `allocated`, `a`.`allocated_by` AS `allocated_by`, `a`.`patient_name` AS `patient_name`, `a`.`patient_id` AS `patient_id`, `a`.`accountNo` AS `accountNo`, `b`.`name` AS `name`, `b`.`class_type` AS `class_type`, `b`.`account` AS `account`, `b`.`price` AS `price`, `a`.`facilityId` AS `facilityId`, `a`.`status` AS `status`, `a`.`seen_by` AS `seen_by` FROM (`patient_bed` `a` join `bedlist` `b` on(`a`.`bed_id` = `b`.`id`)) WHERE `a`.`facilityId` = `b`.`facilityId` ;

-- --------------------------------------------------------

--
-- Structure for view `lab_info`
--
DROP TABLE IF EXISTS `lab_info`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lab_info`  AS SELECT `b`.`sort_index` AS `sort_index`, `b`.`sort_index` AS `sn`, `a`.`created_at` AS `created_at`, `a`.`facilityId` AS `facilityId`, `a`.`id` AS `id`, `a`.`code` AS `code`, `a`.`booking_no` AS `booking_no`, `a`.`request_id` AS `request_id`, `a`.`patient_id` AS `patient_id`, concat(`c`.`firstname`,' ',`c`.`surname`) AS `name`, `c`.`DOB` AS `DOB`, `c`.`Gender` AS `Gender`, `b`.`qms_dept_id` AS `qms_dept_id`, `b`.`head` AS `head`, `b`.`subhead` AS `subhead`, `b`.`unit` AS `unit`, `b`.`range_from` AS `range_from`, `b`.`range_to` AS `range_to`, `b`.`price` AS `price`, `b`.`old_price` AS `old_price`, `a`.`modeOfPayment` AS `modeOfPayment`, `b`.`account` AS `account`, `b`.`account_name` AS `account_name`, `b`.`payable_head` AS `payable_head`, `b`.`payable_head_name` AS `payable_head_name`, `b`.`receivable_head` AS `receivable_head`, `b`.`receivable_head_name` AS `receivable_head_name`, `b`.`commission_type` AS `commission_type`, `b`.`percentage` AS `percentage`, `b`.`description` AS `description`, `a`.`test` AS `test`, `a`.`test_group` AS `test_group`, `b`.`specimen` AS `specimen`, `a`.`noOfLabels` AS `noOfLabels`, `a`.`label_type` AS `label_type`, `b`.`label_name` AS `label_name`, `a`.`department` AS `department`, `a`.`unit_name` AS `unit_name`, `a`.`unit_code` AS `unit_code`, `a`.`result` AS `result`, `a`.`h_value` AS `h_value`, `a`.`o_value` AS `o_value`, `a`.`appearance` AS `appearance`, `a`.`serology` AS `serology`, `a`.`culture_yielded` AS `culture_yielded`, `a`.`sensitivity` AS `sensitivity`, `a`.`resistivity` AS `resistivity`, `a`.`intermediaryTo` AS `intermediaryTo`, `b`.`lab_code` AS `lab_code`, `b`.`selectable` AS `selectable`, `a`.`status` AS `status`, `a`.`print_type` AS `print_type`, `b`.`report_type` AS `report_type`, `b`.`collect_sample` AS `collect_sample`, `b`.`to_be_reported` AS `to_be_reported`, `b`.`to_be_analyzed` AS `to_be_analyzed`, `a`.`created_by` AS `created_by`, `a`.`sample_collected_by` AS `sample_collected_by`, `a`.`sample_collected_at` AS `sample_collected_at`, `a`.`analyzed_by` AS `analyzed_by`, `a`.`analyzed_at` AS `analyzed_at`, `a`.`result_by` AS `result_by`, `a`.`result_at` AS `result_at`, `a`.`reviewed_by` AS `reviewed_by`, `a`.`reviewed_at` AS `reviewed_at`, `a`.`printed_by` AS `printed_by`, `a`.`printed_at` AS `printed_at`, `a`.`unit` AS `n_unit`, `a`.`range_from` AS `n_range_from`, `a`.`range_to` AS `n_range_to`, `a`.`receiptNo` AS `receiptNo`, `a`.`sop_instance_id` AS `sop_instance_id`, `a`.`uploaded_at` AS `uploaded_at`, `a`.`uploaded_by` AS `uploaded_by`, `a`.`payment_status` AS `payment_status`, `a`.`approval_status` AS `approval_status`, `a`.`report_fee_status` AS `report_fee_status`, `a`.`department_head` AS `department_head`, `a`.`group_head` AS `group_head`, `a`.`patient_status` AS `patient_status`, `b`.`printable` AS `printable` FROM ((`lab_setup` `b` join `lab_requisition` `a` on(convert(`b`.`subhead` using utf8mb4) = `a`.`test`)) join `patientrecords` `c` on(`a`.`patient_id` = convert(`c`.`id` using utf8mb4))) WHERE `a`.`facilityId` = convert(`b`.`facilityId` using utf8mb4) ;

-- --------------------------------------------------------

--
-- Structure for view `lab_info_2`
--
DROP TABLE IF EXISTS `lab_info_2`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lab_info_2`  AS SELECT `b`.`sort_index` AS `sn`, `a`.`created_at` AS `created_at`, `a`.`facilityId` AS `facilityId`, `a`.`id` AS `id`, `a`.`code` AS `code`, `a`.`booking_no` AS `booking_no`, `a`.`request_id` AS `request_id`, `a`.`patient_id` AS `patient_id`, concat(`c`.`firstname`,' ',`c`.`surname`) AS `name`, `c`.`DOB` AS `DOB`, `c`.`Gender` AS `Gender`, `b`.`qms_dept_id` AS `qms_dept_id`, `b`.`head` AS `head`, `b`.`subhead` AS `subhead`, `b`.`unit` AS `unit`, `b`.`range_from` AS `range_from`, `b`.`range_to` AS `range_to`, `b`.`price` AS `price`, `b`.`old_price` AS `old_price`, `a`.`modeOfPayment` AS `modeOfPayment`, `b`.`account` AS `account`, `b`.`account_name` AS `account_name`, `b`.`payable_head` AS `payable_head`, `b`.`payable_head_name` AS `payable_head_name`, `b`.`receivable_head` AS `receivable_head`, `b`.`receivable_head_name` AS `receivable_head_name`, `b`.`commission_type` AS `commission_type`, `b`.`percentage` AS `percentage`, `b`.`description` AS `description`, `a`.`test` AS `test`, `a`.`test_group` AS `test_group`, `b`.`specimen` AS `specimen`, `a`.`noOfLabels` AS `noOfLabels`, `a`.`label_type` AS `label_type`, `b`.`label_name` AS `label_name`, `a`.`department` AS `department`, `a`.`unit_name` AS `unit_name`, `a`.`unit_code` AS `unit_code`, `a`.`result` AS `result`, `a`.`h_value` AS `h_value`, `a`.`o_value` AS `o_value`, `a`.`appearance` AS `appearance`, `a`.`serology` AS `serology`, `a`.`culture_yielded` AS `culture_yielded`, `a`.`sensitivity` AS `sensitivity`, `a`.`resistivity` AS `resistivity`, `a`.`intermediaryTo` AS `intermediaryTo`, `b`.`lab_code` AS `lab_code`, `b`.`selectable` AS `selectable`, `a`.`status` AS `status`, `a`.`print_type` AS `print_type`, `b`.`report_type` AS `report_type`, `b`.`collect_sample` AS `collect_sample`, `b`.`to_be_reported` AS `to_be_reported`, `b`.`to_be_analyzed` AS `to_be_analyzed`, `a`.`created_by` AS `created_by`, `a`.`sample_collected_by` AS `sample_collected_by`, `a`.`sample_collected_at` AS `sample_collected_at`, `a`.`analyzed_by` AS `analyzed_by`, `a`.`analyzed_at` AS `analyzed_at`, `a`.`result_by` AS `result_by`, `a`.`result_at` AS `result_at`, `a`.`reviewed_by` AS `reviewed_by`, `a`.`reviewed_at` AS `reviewed_at`, `a`.`printed_by` AS `printed_by`, `a`.`printed_at` AS `printed_at`, `a`.`unit` AS `n_unit`, `a`.`range_from` AS `n_range_from`, `a`.`range_to` AS `n_range_to`, `a`.`receiptNo` AS `receiptNo`, `a`.`sop_instance_id` AS `sop_instance_id`, `a`.`uploaded_at` AS `uploaded_at`, `a`.`uploaded_by` AS `uploaded_by`, `a`.`payment_status` AS `payment_status`, `a`.`approval_status` AS `approval_status`, `a`.`report_fee_status` AS `report_fee_status`, `a`.`department_head` AS `department_head`, `a`.`group_head` AS `group_head`, `a`.`patient_status` AS `patient_status` FROM ((`lab_setup` `b` join `lab_requisition` `a` on(convert(`b`.`subhead` using utf8mb4) = `a`.`test`)) join `patientrecords` `c` on(`a`.`patient_id` = convert(`c`.`id` using utf8mb4))) WHERE `a`.`facilityId` = convert(`b`.`facilityId` using utf8mb4) ;

-- --------------------------------------------------------

--
-- Structure for view `lab_process`
--
DROP TABLE IF EXISTS `lab_process`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lab_process`  AS SELECT `a`.`sn` AS `sn`, `a`.`created_at` AS `created_at`, `a`.`facilityId` AS `facilityId`, `a`.`id` AS `id`, `a`.`qms_dept_id` AS `qms_dept_id`, `a`.`code` AS `code`, `a`.`booking_no` AS `booking_no`, `a`.`request_id` AS `request_id`, `a`.`patient_id` AS `patient_id`, `a`.`name` AS `name`, `a`.`DOB` AS `DOB`, `a`.`Gender` AS `Gender`, `a`.`head` AS `head`, `a`.`subhead` AS `subhead`, `a`.`unit` AS `unit`, `a`.`range_from` AS `range_from`, `a`.`range_to` AS `range_to`, `a`.`price` AS `price`, `a`.`old_price` AS `old_price`, `a`.`commission_type` AS `commission_type`, `a`.`percentage` AS `percentage`, `a`.`description` AS `description`, `a`.`specimen` AS `specimen`, `a`.`noOfLabels` AS `noOfLabels`, `a`.`label_type` AS `label_type`, `a`.`label_name` AS `label_name`, `a`.`group_head` AS `group_head`, `a`.`department` AS `department`, `b`.`description` AS `department_head`, `a`.`result` AS `result`, `a`.`h_value` AS `h_value`, `a`.`o_value` AS `o_value`, `a`.`appearance` AS `appearance`, `a`.`serology` AS `serology`, `a`.`culture_yielded` AS `culture_yielded`, `a`.`sensitivity` AS `sensitivity`, `a`.`resistivity` AS `resistivity`, `a`.`intermediaryTo` AS `intermediaryTo`, `a`.`lab_code` AS `lab_code`, `a`.`selectable` AS `selectable`, `a`.`status` AS `status`, `a`.`unit_code` AS `unit_code`, `a`.`unit_name` AS `unit_name`, `a`.`print_type` AS `print_type`, `a`.`report_type` AS `report_type`, `a`.`collect_sample` AS `collect_sample`, `a`.`to_be_reported` AS `to_be_reported`, `a`.`to_be_analyzed` AS `to_be_analyzed`, `a`.`created_by` AS `created_by`, `a`.`sample_collected_by` AS `sample_collected_by`, `a`.`sample_collected_at` AS `sample_collected_at`, `a`.`analyzed_by` AS `analyzed_by`, `a`.`analyzed_at` AS `analyzed_at`, `a`.`result_by` AS `result_by`, `a`.`result_at` AS `result_at`, `a`.`reviewed_by` AS `reviewed_by`, `a`.`reviewed_at` AS `reviewed_at`, `a`.`printed_by` AS `printed_by`, `a`.`printed_at` AS `printed_at`, `a`.`n_unit` AS `n_unit`, `a`.`n_range_from` AS `n_range_from`, `a`.`n_range_to` AS `n_range_to`, `a`.`receiptNo` AS `receiptNo`, `a`.`sop_instance_id` AS `sop_instance_id`, `a`.`uploaded_at` AS `uploaded_at`, `a`.`uploaded_by` AS `uploaded_by`, `a`.`payment_status` AS `payment_status`, `a`.`approval_status` AS `approval_status`, `a`.`patient_status` AS `patient_status`, `a`.`test` AS `test`, `a`.`test_group` AS `test_group` FROM (`lab_request2` `a` join `lab_setup` `b`) WHERE `a`.`department` = convert(`b`.`subhead` using utf8mb4) AND `a`.`facilityId` = convert(`b`.`facilityId` using utf8mb4) ;

-- --------------------------------------------------------

--
-- Structure for view `lab_request2`
--
DROP TABLE IF EXISTS `lab_request2`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lab_request2`  AS SELECT `a`.`sn` AS `sn`, `a`.`created_at` AS `created_at`, `a`.`facilityId` AS `facilityId`, `a`.`id` AS `id`, `a`.`qms_dept_id` AS `qms_dept_id`, `a`.`code` AS `code`, `a`.`name` AS `name`, `a`.`DOB` AS `DOB`, `a`.`Gender` AS `Gender`, `a`.`booking_no` AS `booking_no`, `a`.`request_id` AS `request_id`, `a`.`patient_id` AS `patient_id`, `a`.`head` AS `head`, `a`.`subhead` AS `subhead`, `a`.`unit` AS `unit`, `a`.`range_from` AS `range_from`, `a`.`range_to` AS `range_to`, `a`.`price` AS `price`, `a`.`old_price` AS `old_price`, `a`.`commission_type` AS `commission_type`, `a`.`percentage` AS `percentage`, `a`.`description` AS `description`, `a`.`specimen` AS `specimen`, `a`.`noOfLabels` AS `noOfLabels`, `a`.`label_type` AS `label_type`, `a`.`label_name` AS `label_name`, `b`.`description` AS `group_head`, `a`.`department` AS `department`, `a`.`unit_code` AS `unit_code`, `a`.`unit_name` AS `unit_name`, `a`.`result` AS `result`, `a`.`h_value` AS `h_value`, `a`.`o_value` AS `o_value`, `a`.`appearance` AS `appearance`, `a`.`serology` AS `serology`, `a`.`culture_yielded` AS `culture_yielded`, `a`.`sensitivity` AS `sensitivity`, `a`.`resistivity` AS `resistivity`, `a`.`intermediaryTo` AS `intermediaryTo`, `a`.`lab_code` AS `lab_code`, `a`.`selectable` AS `selectable`, `a`.`status` AS `status`, `a`.`print_type` AS `print_type`, `a`.`report_type` AS `report_type`, `b`.`collect_sample` AS `collect_sample`, `b`.`to_be_reported` AS `to_be_reported`, `b`.`to_be_analyzed` AS `to_be_analyzed`, `a`.`created_by` AS `created_by`, `a`.`sample_collected_by` AS `sample_collected_by`, `a`.`sample_collected_at` AS `sample_collected_at`, `a`.`analyzed_by` AS `analyzed_by`, `a`.`analyzed_at` AS `analyzed_at`, `a`.`result_by` AS `result_by`, `a`.`result_at` AS `result_at`, `a`.`reviewed_by` AS `reviewed_by`, `a`.`reviewed_at` AS `reviewed_at`, `a`.`printed_by` AS `printed_by`, `a`.`printed_at` AS `printed_at`, `a`.`n_unit` AS `n_unit`, `a`.`n_range_from` AS `n_range_from`, `a`.`n_range_to` AS `n_range_to`, `a`.`receiptNo` AS `receiptNo`, `a`.`sop_instance_id` AS `sop_instance_id`, `a`.`uploaded_at` AS `uploaded_at`, `a`.`uploaded_by` AS `uploaded_by`, `a`.`payment_status` AS `payment_status`, `a`.`approval_status` AS `approval_status`, `a`.`patient_status` AS `patient_status`, `a`.`test` AS `test`, `a`.`test_group` AS `test_group` FROM (`lab_info` `a` join `lab_setup` `b` on(`b`.`subhead` = `a`.`head`)) WHERE `a`.`facilityId` = convert(`b`.`facilityId` using utf8mb4) ;

-- --------------------------------------------------------

--
-- Structure for view `lab_requests`
--
DROP TABLE IF EXISTS `lab_requests`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lab_requests`  AS SELECT `a`.`department` AS `department`, `a`.`patient_id` AS `patient_id`, `b`.`status` AS `status` FROM (`lab_requisition` `a` join `lab_numbers` `b` on(`a`.`patient_id` = convert(`b`.`patient_id` using utf8mb4))) ;

-- --------------------------------------------------------

--
-- Structure for view `medication_report`
--
DROP TABLE IF EXISTS `medication_report`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `medication_report`  AS SELECT `a`.`patient_id` AS `patient_id`, `a`.`drug` AS `drug`, `a`.`dosage` AS `dosage`, `a`.`route` AS `route`, `a`.`time_stamp` AS `time_stamp`, `a`.`status` AS `status`, `a`.`served_by` AS `served_by`, concat(`b`.`firstname`,' ',`b`.`lastname`) AS `nurse_name`, `a`.`reason` AS `reason` FROM (`drug_schedule_view` `a` join `users` `b` on(`a`.`served_by` = `b`.`username`)) WHERE `a`.`status` in ('Served','Not Served') ;

-- --------------------------------------------------------

--
-- Structure for view `overview`
--
DROP TABLE IF EXISTS `overview`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `overview`  AS SELECT `a`.`drug` AS `drug`, `b`.`quantity` AS `quantity_bought`, `b`.`quantity`* `b`.`cost_price` AS `amount_bought`, `b`.`balance` AS `quantity_in_store`, `b`.`balance`* `b`.`cost_price` AS `amount_in_store`, `a`.`qty_out` AS `quantity_sold`, (`a`.`price` + `a`.`markup`) * `a`.`qty_out` AS `amount_sold`, `b`.`dispensary_balance`- `a`.`qty_out` AS `quantity_in_shelf`, (`b`.`dispensary_balance` - `a`.`qty_out`) * (`a`.`price` + `a`.`markup`) AS `amount_in_shelf`, `a`.`created_at` AS `sales_date`, `b`.`created_at` AS `purchase_date`, `a`.`facilityId` AS `facilityId` FROM (`drugs` `a` join `drugpurchaserecords` `b` on(`a`.`drug_code` = `b`.`drug_code`)) WHERE `a`.`source` = 'dispensary' AND `a`.`qty_out` <> 0 ;

-- --------------------------------------------------------

--
-- Structure for view `overview_wo_store`
--
DROP TABLE IF EXISTS `overview_wo_store`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `overview_wo_store`  AS SELECT `drugs`.`drug` AS `drug`, `drugs`.`price`+ `drugs`.`markup` AS `price`, sum(`drugs`.`qty_in`) - sum(`drugs`.`qty_out`) AS `quantity_in_shelf`, (sum(`drugs`.`qty_in`) - sum(`drugs`.`qty_out`)) * `drugs`.`price` + `drugs`.`markup` AS `amount_in_shelf`, (select sum(`drugs`.`qty_in`) - sum(`drugs`.`qty_out`) from `drugs` where `drugs`.`source` = 'sold_items') AS `quantity_sold`, (select sum(`drugs`.`qty_in`) - sum(`drugs`.`qty_out`) from `drugs` where `drugs`.`source` = 'sold_items') * (`drugs`.`price` + `drugs`.`markup`) AS `amount_sold`, `drugs`.`expiry_date` AS `expiry_date`, `drugs`.`created_at` AS `created_at`, `drugs`.`facilityId` AS `facilityId` FROM `drugs` WHERE `drugs`.`source` = 'dispensary' ;

-- --------------------------------------------------------

--
-- Structure for view `patientfileno_full`
--
DROP TABLE IF EXISTS `patientfileno_full`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `patientfileno_full`  AS SELECT `patientfileno`.`id` AS `id`, count(`patientfileno`.`accountNo`) AS `acc_count`, `patientfileno`.`accountNo` AS `accountNo`, `patientfileno`.`beneficiaries` AS `beneficiaries`, `patientfileno`.`firstname` AS `firstname`, `patientfileno`.`surname` AS `surname`, `patientfileno`.`status` AS `status`, `patientfileno`.`createdAt` AS `createdAt`, `patientfileno`.`accName` AS `accName`, `patientfileno`.`description` AS `description`, `patientfileno`.`accountType` AS `accountType`, `patientfileno`.`contactName` AS `contactName`, `patientfileno`.`contactAddress` AS `contactAddress`, `patientfileno`.`contactPhone` AS `contactPhone`, `patientfileno`.`contactEmail` AS `contactEmail`, `patientfileno`.`contactWebsite` AS `contactWebsite`, `patientfileno`.`balance` AS `balance`, `patientfileno`.`guarantor_name` AS `guarantor_name`, `patientfileno`.`guarantor_address` AS `guarantor_address`, `patientfileno`.`guarantor_phone` AS `guarantor_phone`, `patientfileno`.`created_by` AS `created_by`, `patientfileno`.`approved_by` AS `approved_by`, `patientfileno`.`approved_at` AS `approved_at` FROM `patientfileno` GROUP BY `patientfileno`.`accountNo`, `patientfileno`.`firstname`, `patientfileno`.`surname`, `patientfileno`.`beneficiaries` ORDER BY `patientfileno`.`accountNo` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `patient_bed`
--
DROP TABLE IF EXISTS `patient_bed`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `patient_bed`  AS SELECT `a`.`id` AS `allocation_id`, `a`.`bed_id` AS `bed_id`, `a`.`allocated` AS `allocated`, `a`.`allocated_by` AS `allocated_by`, `a`.`allocation_status` AS `allocation_status`, concat(`b`.`surname`,' ',`b`.`firstname`) AS `patient_name`, `a`.`patient_id` AS `patient_id`, `b`.`accountNo` AS `accountNo`, `a`.`facilityId` AS `facilityId`, `b`.`patientStatus` AS `status`, `b`.`seen_by` AS `seen_by` FROM (`bed_allocation` `a` join `patientrecords` `b` on(`a`.`patient_id` = `b`.`id`)) WHERE `a`.`facilityId` = `b`.`facilityId` AND `a`.`ended` is null ;

-- --------------------------------------------------------

--
-- Structure for view `saved_pending_request`
--
DROP TABLE IF EXISTS `saved_pending_request`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `saved_pending_request`  AS   (select distinct `a`.`booking_no` AS `labno`,`a`.`booking_no` AS `booking_no`,concat(`b`.`surname`,' ',`b`.`firstname`) AS `name`,`a`.`code` AS `code`,`a`.`patient_id` AS `patient_id`,`a`.`status` AS `status`,`a`.`department_head` AS `department`,`a`.`head` AS `head`,`a`.`group_head` AS `test_group`,`a`.`description` AS `description`,`a`.`subhead` AS `subhead` from (`lab_info` `a` join `patientrecords` `b` on(`a`.`patient_id` = convert(`b`.`id` using utf8mb4))) where `a`.`status` in ('Sample Collected','saved') and `a`.`facilityId` = '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a' and `b`.`facilityId` = '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a')  ;

-- --------------------------------------------------------

--
-- Structure for view `test1`
--
DROP TABLE IF EXISTS `test1`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `test1`  AS SELECT DISTINCT `a`.`head` AS `head`, `a`.`subhead` AS `subhead`, `a`.`description` AS `des`, `b`.`acct` AS `acct`, `b`.`debit` AS `debit`, `b`.`credit` AS `credit`, `b`.`description` AS `description`, `b`.`facilityId` AS `facilityId`, `b`.`transaction_date` AS `createdAt`, `b`.`transaction_date` AS `transaction_date`, `b`.`transaction_id` AS `transaction_id`, `b`.`enteredBy` AS `enteredBy`, `b`.`receiptDateSN` AS `receiptDateSN`, `b`.`receiptNo` AS `receiptNo`, `b`.`modeOfPayment` AS `modeOfPayment`, `b`.`status` AS `status`, `b`.`approvedBy` AS `approvedBy`, `b`.`paymentStatus` AS `paymentStatus`, `b`.`client_acct` AS `client_acct`, `b`.`patient_id` AS `patient_id` FROM (`account` `a` join `transactions` `b` on(`b`.`acct` = `a`.`head`)) WHERE `b`.`status` = 'pending' ;

-- --------------------------------------------------------

--
-- Structure for view `transaction_view`
--
DROP TABLE IF EXISTS `transaction_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `transaction_view`  AS SELECT `transactions`.`facilityId` AS `facilityId`, `transactions`.`transaction_date` AS `createdAt`, `transactions`.`acct` AS `acct`, `transactions`.`debit` AS `debit`, `transactions`.`description` AS `description`, `transactions`.`patient_id` AS `patient_id` FROM `transactions` WHERE `transactions`.`debit` <> 0 ;

-- --------------------------------------------------------

--
-- Structure for view `transaction_view2`
--
DROP TABLE IF EXISTS `transaction_view2`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `transaction_view2`  AS SELECT `drugs`.`created_at` AS `date`, `drugs`.`drug` AS `drug`, `drugs`.`qty_in` AS `quantity`, `drugs`.`price` AS `price`, `drugs`.`qty_in`* `drugs`.`markup` AS `profit`, (`drugs`.`price` + `drugs`.`markup`) * `drugs`.`qty_in` AS `amount`, `drugs`.`facilityId` AS `facilityId` FROM `drugs` WHERE `drugs`.`source` = 'dispensary' AND `drugs`.`qty_in` <> 0 ;

-- --------------------------------------------------------

--
-- Structure for view `trialbalance`
--
DROP TABLE IF EXISTS `trialbalance`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `trialbalance`  AS SELECT `a`.`head` AS `head`, `a`.`subhead` AS `subhead`, `a`.`des` AS `des`, `a`.`acct` AS `acct`, `b`.`description` AS `description`, sum(`a`.`debit`) - sum(`a`.`credit`) AS `debit`, sum(`a`.`credit`) - sum(`a`.`debit`) AS `credit`, cast(`a`.`transaction_date` as date) AS `createdAt`, cast(`a`.`transaction_date` as date) AS `date`, `a`.`facilityId` AS `facilityId` FROM (`test1` `a` join `account` `b` on(`a`.`subhead` = `b`.`head`)) GROUP BY `a`.`head`, `a`.`subhead`, `b`.`head`, `a`.`des`, `a`.`acct`, `b`.`description`<> 0 ;

-- --------------------------------------------------------

--
-- Structure for view `trial_balance`
--
DROP TABLE IF EXISTS `trial_balance`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `trial_balance`  AS SELECT DISTINCT `a`.`acct` AS `acct`, `a`.`description` AS `narration`, `a`.`des` AS `Acct_source`, `b`.`description` AS `parent_account`, `a`.`debit` AS `debit`, `a`.`credit` AS `credit`, `b`.`facilityId` AS `facilityId`, `a`.`transaction_date` AS `createdAt`, `a`.`transaction_date` AS `created_at`, `a`.`enteredBy` AS `enteredBy`, `a`.`receiptDateSN` AS `receiptDateSN`, `a`.`receiptNo` AS `receiptNo`, `a`.`modeOfPayment` AS `modeOfPayment`, `a`.`client_acct` AS `client_acct` FROM (`test1` `a` join `account` `b`) WHERE `a`.`subhead` = `b`.`head` AND `a`.`status` = 'pending' ;

-- --------------------------------------------------------

--
-- Structure for view `view_all_bed_allocations`
--
DROP TABLE IF EXISTS `view_all_bed_allocations`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_all_bed_allocations`  AS SELECT `a`.`id` AS `allocation_id`, `a`.`bed_id` AS `bed_id`, `a`.`ended` AS `ended`, `a`.`allocated_by` AS `allocated_by`, `a`.`ended_by` AS `ended_by`, `a`.`allocation_status` AS `allocation_status`, `a`.`allocated` AS `created_at`, concat(`b`.`surname`,' ',`b`.`firstname`) AS `patient_name`, `a`.`patient_id` AS `patient_id`, `b`.`accountNo` AS `accountNo`, `a`.`facilityId` AS `facilityId` FROM (`bed_allocation` `a` join `patientrecords` `b` on(`a`.`patient_id` = `b`.`id`)) WHERE `a`.`facilityId` = `b`.`facilityId` AND `a`.`ended` is not null ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `account4`
--
ALTER TABLE `account4`
  ADD PRIMARY KEY (`head`,`facilityId`);

--
-- Indexes for table `account_entries`
--
ALTER TABLE `account_entries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `facilityId` (`facilityId`,`createdAt`),
  ADD KEY `acct` (`acct`);

--
-- Indexes for table `account_opt`
--
ALTER TABLE `account_opt`
  ADD PRIMARY KEY (`head`,`facilityId`);

--
-- Indexes for table `account_ubec`
--
ALTER TABLE `account_ubec`
  ADD PRIMARY KEY (`head`,`facilityId`);

--
-- Indexes for table `appointment`
--
ALTER TABLE `appointment`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `appointments`
--
ALTER TABLE `appointments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `referenceNumber` (`referenceNumber`);

--
-- Indexes for table `attendance`
--
ALTER TABLE `attendance`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `bedlist`
--
ALTER TABLE `bedlist`
  ADD PRIMARY KEY (`id`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `class_type` (`class_type`),
  ADD KEY `id` (`id`);

--
-- Indexes for table `beds`
--
ALTER TABLE `beds`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `bed_allocation`
--
ALTER TABLE `bed_allocation`
  ADD PRIMARY KEY (`id`),
  ADD KEY `allocation_status` (`allocation_status`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `allocated_by` (`allocated_by`),
  ADD KEY `ended` (`ended`),
  ADD KEY `allocated` (`allocated`),
  ADD KEY `bed_id` (`bed_id`);

--
-- Indexes for table `blogs`
--
ALTER TABLE `blogs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `charges_fees`
--
ALTER TABLE `charges_fees`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `charges_fees_temp`
--
ALTER TABLE `charges_fees_temp`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `chatbot_sessions`
--
ALTER TABLE `chatbot_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `sessionId` (`sessionId`);

--
-- Indexes for table `comment`
--
ALTER TABLE `comment`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `comments`
--
ALTER TABLE `comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `post_id` (`post_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `consultations`
--
ALTER TABLE `consultations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `created_at` (`created_at`),
  ADD KEY `decision` (`decision`),
  ADD KEY `nursing_request_status` (`nursing_request_status`),
  ADD KEY `treatment_plan_status` (`treatment_plan_status`),
  ADD KEY `treatment_by` (`treatment_by`),
  ADD KEY `userId` (`userId`);

--
-- Indexes for table `contacts`
--
ALTER TABLE `contacts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `department`
--
ALTER TABLE `department`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `diagnosis`
--
ALTER TABLE `diagnosis`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `dieselrefuel`
--
ALTER TABLE `dieselrefuel`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `dieselusage`
--
ALTER TABLE `dieselusage`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `discharge_reports`
--
ALTER TABLE `discharge_reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `patient_id` (`patient_id`);

--
-- Indexes for table `discount`
--
ALTER TABLE `discount`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `dispensary`
--
ALTER TABLE `dispensary`
  ADD PRIMARY KEY (`id`),
  ADD KEY `request_id` (`request_id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `receiptNo` (`receiptNo`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `created_at` (`created_at`),
  ADD KEY `status` (`status`),
  ADD KEY `schedule_status` (`schedule_status`),
  ADD KEY `end_date` (`end_date`);

--
-- Indexes for table `druglist`
--
ALTER TABLE `druglist`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `drugpurchaserecords`
--
ALTER TABLE `drugpurchaserecords`
  ADD PRIMARY KEY (`drug`,`expiry_date`,`cost_price`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `status` (`status`),
  ADD KEY `balance` (`balance`),
  ADD KEY `created_at` (`created_at`),
  ADD KEY `supplier` (`supplier`),
  ADD KEY `expiry_date` (`expiry_date`),
  ADD KEY `quantity` (`quantity`);

--
-- Indexes for table `drug_frequency`
--
ALTER TABLE `drug_frequency`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `drug_frequency4`
--
ALTER TABLE `drug_frequency4`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `drug_frequency4_x`
--
ALTER TABLE `drug_frequency4_x`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `drug_frequency4_y`
--
ALTER TABLE `drug_frequency4_y`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `drug_interaction`
--
ALTER TABLE `drug_interaction`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_resource` (`resource`,`resource_id`);

--
-- Indexes for table `drug_schedule`
--
ALTER TABLE `drug_schedule`
  ADD PRIMARY KEY (`id`),
  ADD KEY `prescription_id` (`prescription_id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `status` (`status`),
  ADD KEY `served_by` (`served_by`),
  ADD KEY `administered_by` (`administered_by`),
  ADD KEY `allocation_id` (`allocation_id`);

--
-- Indexes for table `feedbacks`
--
ALTER TABLE `feedbacks`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `fluid_chart`
--
ALTER TABLE `fluid_chart`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `group_service`
--
ALTER TABLE `group_service`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `hmo_registration_table`
--
ALTER TABLE `hmo_registration_table`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `hospitals`
--
ALTER TABLE `hospitals`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `hour_list`
--
ALTER TABLE `hour_list`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `hour_list_x`
--
ALTER TABLE `hour_list_x`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `icd_code`
--
ALTER TABLE `icd_code`
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `insuranceTable`
--
ALTER TABLE `insuranceTable`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `lab`
--
ALTER TABLE `lab`
  ADD PRIMARY KEY (`test_id`);

--
-- Indexes for table `labservices`
--
ALTER TABLE `labservices`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `lab_inventory_table`
--
ALTER TABLE `lab_inventory_table`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `lab_numbers`
--
ALTER TABLE `lab_numbers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `lab_requisition`
--
ALTER TABLE `lab_requisition`
  ADD PRIMARY KEY (`facilityId`,`id`),
  ADD KEY `test` (`test`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `booking_no` (`booking_no`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `request_id` (`request_id`),
  ADD KEY `test_group` (`test_group`),
  ADD KEY `id` (`id`),
  ADD KEY `department` (`department`),
  ADD KEY `status` (`status`),
  ADD KEY `created_at` (`created_at`,`updated_at`,`sample_collected_at`,`analyzed_at`,`result_at`,`uploaded_at`,`reviewed_at`,`printed_at`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `sample_collected_by` (`sample_collected_by`,`analyzed_by`,`result_by`,`uploaded_by`,`reviewed_by`,`printed_by`),
  ADD KEY `receiptNo` (`receiptNo`),
  ADD KEY `print_type` (`print_type`),
  ADD KEY `department_code` (`department_code`),
  ADD KEY `client_account` (`client_account`),
  ADD KEY `client_type` (`client_type`),
  ADD KEY `patient_status` (`patient_status`),
  ADD KEY `patient_name` (`patient_name`);

--
-- Indexes for table `lab_setup`
--
ALTER TABLE `lab_setup`
  ADD PRIMARY KEY (`subhead`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `subhead` (`subhead`),
  ADD KEY `head` (`head`);

--
-- Indexes for table `lab_setup3`
--
ALTER TABLE `lab_setup3`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `lab_setup4`
--
ALTER TABLE `lab_setup4`
  ADD PRIMARY KEY (`subhead`,`facilityId`);

--
-- Indexes for table `number_generator`
--
ALTER TABLE `number_generator`
  ADD PRIMARY KEY (`prefix`);

--
-- Indexes for table `nursing_note`
--
ALTER TABLE `nursing_note`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `nursing_report`
--
ALTER TABLE `nursing_report`
  ADD PRIMARY KEY (`id`),
  ADD KEY `created_at` (`created_at`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `operationnotes`
--
ALTER TABLE `operationnotes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `patientId` (`patientId`),
  ADD KEY `facilityId` (`facilityId`);

--
-- Indexes for table `pagenavigation`
--
ALTER TABLE `pagenavigation`
  ADD PRIMARY KEY (`id`),
  ADD KEY `role` (`role`),
  ADD KEY `facilityId` (`facilityId`);

--
-- Indexes for table `patientfileinfo`
--
ALTER TABLE `patientfileinfo`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `patientfileno`
--
ALTER TABLE `patientfileno`
  ADD PRIMARY KEY (`id`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `accountNo` (`accountNo`);

--
-- Indexes for table `patientrecords`
--
ALTER TABLE `patientrecords`
  ADD PRIMARY KEY (`facilityId`,`id`,`patient_id`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `seen_by` (`seen_by`,`date_seen`),
  ADD KEY `accountNo` (`accountNo`),
  ADD KEY `status` (`status`),
  ADD KEY `assigned_to` (`assigned_to`),
  ADD KEY `patientStatus` (`patientStatus`),
  ADD KEY `id` (`id`),
  ADD KEY `surname` (`surname`,`firstname`),
  ADD KEY `assigned_to_2` (`assigned_to`);

--
-- Indexes for table `patient_ai_summaries`
--
ALTER TABLE `patient_ai_summaries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `patient_id` (`patient_id`);

--
-- Indexes for table `patient_history`
--
ALTER TABLE `patient_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `request_id` (`request_id`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `createdAt` (`createdAt`);

--
-- Indexes for table `pending_txn`
--
ALTER TABLE `pending_txn`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pharm_branches`
--
ALTER TABLE `pharm_branches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pharm_store`
--
ALTER TABLE `pharm_store`
  ADD PRIMARY KEY (`item_code`,`facilityId`,`expiry_date`,`store`,`selling_price`),
  ADD UNIQUE KEY `item_id` (`item_id`);

--
-- Indexes for table `pharm_store_entries`
--
ALTER TABLE `pharm_store_entries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `transfer_from` (`transfer_from`,`transfer_to`,`branch_name`,`facilityId`),
  ADD KEY `inserted_time` (`inserted_time`);

--
-- Indexes for table `posts`
--
ALTER TABLE `posts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`),
  ADD KEY `author_id` (`author_id`);

--
-- Indexes for table `post_categories`
--
ALTER TABLE `post_categories`
  ADD PRIMARY KEY (`post_id`,`category_id`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `prescriptionrequests`
--
ALTER TABLE `prescriptionrequests`
  ADD PRIMARY KEY (`drug_request_id`);

--
-- Indexes for table `previous_doc`
--
ALTER TABLE `previous_doc`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `referrals`
--
ALTER TABLE `referrals`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `report_templates`
--
ALTER TABLE `report_templates`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sensitivity_list`
--
ALTER TABLE `sensitivity_list`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sensitivity_results`
--
ALTER TABLE `sensitivity_results`
  ADD PRIMARY KEY (`antibiotic`,`labno`);

--
-- Indexes for table `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`service_id`);

--
-- Indexes for table `specimen`
--
ALTER TABLE `specimen`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `suppliersinfo`
--
ALTER TABLE `suppliersinfo`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `supplier_entries`
--
ALTER TABLE `supplier_entries`
  ADD PRIMARY KEY (`entry_id`);

--
-- Indexes for table `surgeons_list`
--
ALTER TABLE `surgeons_list`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `surgical_note`
--
ALTER TABLE `surgical_note`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `surgical_note_temp`
--
ALTER TABLE `surgical_note_temp`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`transaction_id`);

--
-- Indexes for table `transactions3`
--
ALTER TABLE `transactions3`
  ADD PRIMARY KEY (`transaction_id`);

--
-- Indexes for table `transactionsetup`
--
ALTER TABLE `transactionsetup`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `transaction_entries`
--
ALTER TABLE `transaction_entries`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `transfers`
--
ALTER TABLE `transfers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `User Departments`
--
ALTER TABLE `User Departments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`,`facilityId`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `createdAt` (`createdAt`),
  ADD KEY `id` (`id`);

--
-- Indexes for table `vital_signs`
--
ALTER TABLE `vital_signs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `facilityId` (`facilityId`),
  ADD KEY `created_at` (`created_at`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `wholesale_transaction`
--
ALTER TABLE `wholesale_transaction`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `account_entries`
--
ALTER TABLE `account_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=542;

--
-- AUTO_INCREMENT for table `appointment`
--
ALTER TABLE `appointment`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `appointments`
--
ALTER TABLE `appointments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `attendance`
--
ALTER TABLE `attendance`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bedlist`
--
ALTER TABLE `bedlist`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=61;

--
-- AUTO_INCREMENT for table `bed_allocation`
--
ALTER TABLE `bed_allocation`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=121;

--
-- AUTO_INCREMENT for table `blogs`
--
ALTER TABLE `blogs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `charges_fees`
--
ALTER TABLE `charges_fees`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=583;

--
-- AUTO_INCREMENT for table `charges_fees_temp`
--
ALTER TABLE `charges_fees_temp`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `chatbot_sessions`
--
ALTER TABLE `chatbot_sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `comment`
--
ALTER TABLE `comment`
  MODIFY `id` int(100) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `comments`
--
ALTER TABLE `comments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `diagnosis`
--
ALTER TABLE `diagnosis`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `dieselrefuel`
--
ALTER TABLE `dieselrefuel`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `dieselusage`
--
ALTER TABLE `dieselusage`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `discharge_reports`
--
ALTER TABLE `discharge_reports`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `discount`
--
ALTER TABLE `discount`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `druglist`
--
ALTER TABLE `druglist`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=330;

--
-- AUTO_INCREMENT for table `drug_frequency`
--
ALTER TABLE `drug_frequency`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `drug_frequency4`
--
ALTER TABLE `drug_frequency4`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=54;

--
-- AUTO_INCREMENT for table `drug_frequency4_x`
--
ALTER TABLE `drug_frequency4_x`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `drug_frequency4_y`
--
ALTER TABLE `drug_frequency4_y`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT for table `drug_interaction`
--
ALTER TABLE `drug_interaction`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `drug_schedule`
--
ALTER TABLE `drug_schedule`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `fluid_chart`
--
ALTER TABLE `fluid_chart`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hmo_registration_table`
--
ALTER TABLE `hmo_registration_table`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `hour_list`
--
ALTER TABLE `hour_list`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `lab`
--
ALTER TABLE `lab`
  MODIFY `test_id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `labservices`
--
ALTER TABLE `labservices`
  MODIFY `id` int(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `lab_inventory_table`
--
ALTER TABLE `lab_inventory_table`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `lab_requisition`
--
ALTER TABLE `lab_requisition`
  MODIFY `id` int(100) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `nursing_note`
--
ALTER TABLE `nursing_note`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nursing_report`
--
ALTER TABLE `nursing_report`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `operationnotes`
--
ALTER TABLE `operationnotes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2261;

--
-- AUTO_INCREMENT for table `patientfileno`
--
ALTER TABLE `patientfileno`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT for table `patientrecords`
--
ALTER TABLE `patientrecords`
  MODIFY `patient_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `patient_ai_summaries`
--
ALTER TABLE `patient_ai_summaries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pending_txn`
--
ALTER TABLE `pending_txn`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=212;

--
-- AUTO_INCREMENT for table `pharm_store_entries`
--
ALTER TABLE `pharm_store_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=445;

--
-- AUTO_INCREMENT for table `posts`
--
ALTER TABLE `posts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `previous_doc`
--
ALTER TABLE `previous_doc`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `sensitivity_list`
--
ALTER TABLE `sensitivity_list`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `services`
--
ALTER TABLE `services`
  MODIFY `service_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=56;

--
-- AUTO_INCREMENT for table `suppliersinfo`
--
ALTER TABLE `suppliersinfo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `supplier_entries`
--
ALTER TABLE `supplier_entries`
  MODIFY `entry_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `surgeons_list`
--
ALTER TABLE `surgeons_list`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=232;

--
-- AUTO_INCREMENT for table `surgical_note`
--
ALTER TABLE `surgical_note`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2868;

--
-- AUTO_INCREMENT for table `transfers`
--
ALTER TABLE `transfers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `User Departments`
--
ALTER TABLE `User Departments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=878;

--
-- AUTO_INCREMENT for table `vital_signs`
--
ALTER TABLE `vital_signs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `comments`
--
ALTER TABLE `comments`
  ADD CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `patient_ai_summaries`
--
ALTER TABLE `patient_ai_summaries`
  ADD CONSTRAINT `patient_ai_summaries_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patientrecords` (`id`);

--
-- Constraints for table `posts`
--
ALTER TABLE `posts`
  ADD CONSTRAINT `posts_ibfk_1` FOREIGN KEY (`author_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `post_categories`
--
ALTER TABLE `post_categories`
  ADD CONSTRAINT `post_categories_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `post_categories_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE;

DELIMITER $$
--
-- Events
--
CREATE DEFINER=`root`@`localhost` EVENT `clear_patient_assignments` ON SCHEDULE EVERY 1 DAY STARTS '2025-05-10 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
  UPDATE patientrecords
  SET assigned_to = '', status = ''
  WHERE assigned_to != '' OR status != '';
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
